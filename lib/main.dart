import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io' show Platform;
import 'memo_list_page.dart';

void main() {
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
  bool _isDark = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadThemePreference();
  }

  // 加载保存的夜间模式偏好
  Future<void> _loadThemePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _isDark = prefs.getBool('isDark') ?? false;
        _isLoading = false;
      });
    } catch (e) {
      // 如果读取失败，使用默认值
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 切换主题并保存
  void toggleTheme() async {
    final newValue = !_isDark;
    setState(() {
      _isDark = newValue;
    });
    // 保存到 SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isDark', newValue);
    } catch (e) {
      // 保存失败不影响体验
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      // 加载过程中显示空白或加载指示器
      return const MaterialApp(
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

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