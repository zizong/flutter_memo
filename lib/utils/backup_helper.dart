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

/// 导出所有数据为 JSON 文件（支持桌面平台）
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

    // 针对桌面平台的处理
    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      // 使用应用文档目录作为默认保存位置
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'memo_backup_${DateTime.now().millisecondsSinceEpoch}.json';
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(bytes, mode: FileMode.write);
      return '数据已导出到：$filePath\n\n您可以在文件管理器中找到此文件。';
    }

    // Android / iOS 使用 file_picker
    String? outputFile = await FilePicker.platform.saveFile(
      dialogTitle: '保存备忘录备份',
      fileName: 'memo_backup_${DateTime.now().millisecondsSinceEpoch}.json',
    );

    if (outputFile == null) {
      return null; // 用户取消
    }

    final file = File(outputFile);
    await file.writeAsBytes(bytes, mode: FileMode.write);
    return '数据已导出到：$outputFile';
  } catch (e) {
    return '导出失败：$e';
  }
}

/// 导入数据（支持桌面平台）
Future<String?> importData() async {
  try {
    if (await _requestStoragePermission() == false) {
      return '需要存储权限才能导入数据';
    }

    // 针对桌面平台：从应用文档目录读取
    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/memo_backup_*.json';
      // 让用户选择文件（仅支持单文件）
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        dialogTitle: '选择备份文件',
        type: FileType.any,
        initialDirectory: directory.path,
      );
      if (result == null || result.files.isEmpty) {
        return null;
      }
      final file = File(result.files.single.path!);
      if (!file.path.endsWith('.json')) {
        return '请选择 JSON 格式的备份文件';
      }
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
    }

    // Android / iOS 使用 file_picker
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      dialogTitle: '选择备份文件',
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result == null || result.files.isEmpty) {
      return null;
    }

    final file = File(result.files.single.path!);
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