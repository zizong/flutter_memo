import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io' show Platform;
import 'memo_list_page.dart';   // 引用新页面

void main() {
  // Linux 桌面环境需要额外初始化 sqflite
  if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDark = false; // 当前是否为夜间模式

  void toggleTheme() {
    setState(() {
      _isDark = !_isDark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '我的备忘录',
      theme: _isDark ? ThemeData.dark() : ThemeData.light(),
      home: MemoListPage(
        onThemeToggle: toggleTheme,
        isDark: _isDark,
      ),
    );
  }
}
