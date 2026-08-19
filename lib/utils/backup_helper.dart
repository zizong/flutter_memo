import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/memo.dart';
import '../database/db_helper.dart';

class BackupHelper {
  final DBHelper _db = DBHelper();

  /// 导出所有数据为 JSON 文件
  Future<String?> exportData() async {
    try {
      if (await _requestStoragePermission() == false) {
        return '需要存储权限才能导出数据';
      }

      final memos = await _db.getAllMemos();
      if (memos.isEmpty) {
        return '没有可导出的数据';
      }

      final jsonList = memos.map((memo) => {
        'id': memo.id,
        'title': memo.title,
        'content': memo.content,
        'createdAt': memo.createdAt.toIso8601String(),
      }).toList();

      final jsonString = jsonEncode(jsonList);
      final bytes = Uint8List.fromList(utf8.encode(jsonString));

      // 检查 Android 版本
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      final sdkInt = androidInfo.version.sdkInt;

      if (sdkInt >= 30) {
        // Android 11+ 使用 file_picker
        String? outputFile = await FilePicker.platform.saveFile(
          dialogTitle: '保存备忘录备份',
          fileName: 'memo_backup_${DateTime.now().millisecondsSinceEpoch}.json',
        );
        if (outputFile == null) return null;
        final file = File(outputFile);
        await file.writeAsBytes(bytes, mode: FileMode.write);
        return '数据已导出到：$outputFile';
      } else {
        // Android 10 及以下（包括 8.1）：保存到公共存储目录
        final directory = await getExternalStorageDirectory();
        if (directory == null) return '无法访问外部存储';
        
        final fileName = 'memo_backup_${DateTime.now().millisecondsSinceEpoch}.json';
        final filePath = '${directory.path}/$fileName';
        final file = File(filePath);
        await file.writeAsBytes(bytes, mode: FileMode.write);

        // 尝试通过系统分享让用户选择保存位置（可选）
        // 或者直接返回路径
        return '数据已导出到：$filePath\n\n您可以在文件管理器中找到此文件。';
      }
    } catch (e) {
      return '导出失败：$e';
    }
  }

  /// 导入数据
  Future<String?> importData() async {
    try {
      if (await _requestStoragePermission() == false) {
        return '需要存储权限才能导入数据';
      }

      // 对于 Android 8.1，使用 FileType.any 并手动验证扩展名
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        dialogTitle: '选择备份文件',
        type: FileType.any,
      );

      if (result == null || result.files.isEmpty) return null;

      final filePath = result.files.single.path!;
      if (!filePath.endsWith('.json')) {
        return '请选择 JSON 格式的备份文件';
      }

      final file = File(filePath);
      final jsonString = await file.readAsString();
      final jsonList = jsonDecode(jsonString) as List<dynamic>;

      int successCount = 0;
      int failCount = 0;

      for (var item in jsonList) {
        try {
          final memo = Memo(
            title: item['title'] ?? '无标题',
            content: item['content'] ?? '',
            createdAt: DateTime.tryParse(item['createdAt'] ?? '') ?? DateTime.now(),
          );
          await _db.insertMemo(memo);
          successCount++;
        } catch (e) {
          failCount++;
        }
      }

      return '导入完成：成功 $successCount 条，失败 $failCount 条';
    } catch (e) {
      return '导入失败：$e';
    }
  }

  /// 请求存储权限
  Future<bool> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      try {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        final sdkInt = androidInfo.version.sdkInt;
        
        if (sdkInt >= 30) {
          final status = await Permission.manageExternalStorage.request();
          return status.isGranted;
        } else {
          final status = await Permission.storage.request();
          return status.isGranted;
        }
      } catch (e) {
        final status = await Permission.storage.request();
        return status.isGranted;
      }
    }
    return true;
  }
}