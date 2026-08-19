import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/memo.dart';
import '../database/db_helper.dart';

class BackupHelper {
  final DBHelper _db = DBHelper();

  /// 导出所有数据为 JSON 文件
  Future<String?> exportData() async {
    try {
      // 请求存储权限（Android 13+ 需要）
      if (await _requestStoragePermission() == false) {
        return '需要存储权限才能导出数据';
      }

      final memos = await _db.getAllMemos();
      if (memos.isEmpty) {
        return '没有可导出的数据';
      }

      // 转换为 JSON
      final jsonList = memos.map((memo) => {
        'id': memo.id,
        'title': memo.title,
        'content': memo.content,
        'createdAt': memo.createdAt.toIso8601String(),
      }).toList();

      final jsonString = jsonEncode(jsonList);

      // 让用户选择保存位置
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: '保存备忘录备份',
        fileName: 'memo_backup_${DateTime.now().millisecondsSinceEpoch}.json',
      );

      if (outputFile == null) {
        return null; // 用户取消
      }

      final file = File(outputFile);
      await file.writeAsString(jsonString, mode: FileMode.write);
      return '数据已导出到：$outputFile';
    } catch (e) {
      return '导出失败：$e';
    }
  }

  /// 导入数据
  Future<String?> importData() async {
    try {
      // 请求存储权限
      if (await _requestStoragePermission() == false) {
        return '需要存储权限才能导入数据';
      }

      // 让用户选择文件
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        dialogTitle: '选择备份文件',
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.isEmpty) {
        return null; // 用户取消
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
    // Android 13+ (API 33+) 不再需要 WRITE_EXTERNAL_STORAGE
    // 使用 file_picker 配合 MANAGE_EXTERNAL_STORAGE 或更细粒度权限
    // 这里简单返回 true，实际可根据平台处理
    if (Platform.isAndroid) {
      final status = await Permission.manageExternalStorage.request();
      return status.isGranted;
    }
    return true; // Linux/Windows 桌面直接读写
  }
}