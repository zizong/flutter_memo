# 📝 我的备忘录 (Memo)

> 一个轻量级跨平台备忘录应用 —— 基于 Flutter，支持 Android / Linux / Windows，现已支持搜索和夜间模式。

[![Flutter](https://img.shields.io/badge/Flutter-3.29+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.12+-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Build Status](https://github.com/zizong/flutter_memo/actions/workflows/build.yml/badge.svg)](https://github.com/zizong/flutter_memo/actions)

---

## ✨ 功能特性

- ✅ **标题 + 正文** —— 每条备忘录都支持标题和详细内容
- 🔍 **实时搜索** —— 按标题或内容快速过滤，不区分大小写
- 🌙 **夜间模式** —— 一键切换深色/浅色主题，保护视力
- 💾 **本地存储** —— 使用 SQLite 数据库，数据永久保存在本地
- 📱 **跨平台** —— 已支持 Android、Linux、Windows（更多平台开发中）
- 🤖 **自动构建** —— 通过 GitHub Actions 自动打包多平台安装包

---

## 📦 下载与安装

### Android
- 从 [GitHub Actions](https://github.com/zizong/flutter_memo/actions) 下载最新 APK（选择 `android-app-arm64-v8a-signed`）

### Linux
1. 下载 `linux-bundle` 压缩包
2. 解压后进入 `bundle/` 目录
3. 运行可执行文件：
   ```bash
   ./flutter_memo
   ```

### Windows
1. 下载 `windows-release` 压缩包
2. 解压后进入 `Release/` 目录
3. 双击 `flutter_memo.exe` 运行

---

## 🛠️ 本地开发

### 环境要求
- Flutter SDK 3.22+
- Android Studio 或 VS Code（推荐）
- 如需构建 Linux 桌面版，需安装以下依赖：
  ```bash
  # Ubuntu/Debian
  sudo apt-get update
  sudo apt-get install -y clang cmake ninja-build pkg-config \
    libgtk-3-dev liblzma-dev libstdc++-12-dev \
    libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev
  ```

### 克隆并运行
```bash
# 克隆仓库
git clone git@github.com:zizong/flutter_memo.git
cd flutter_memo

# 安装依赖
flutter pub get

# 运行（默认 Android 设备）
flutter run

# 或指定平台
flutter run -d linux      # Linux 桌面
flutter run -d windows    # Windows 桌面
```

### 构建生产版本
```bash
# Android APK
flutter build apk --release --target-platform android-arm64

# Linux 桌面
flutter build linux --release

# Windows 桌面（仅限 Windows 主机）
flutter build windows --release
```

---

## 📁 项目结构

```
lib/
├── database/
│   └── db_helper.dart        # SQLite 数据库操作
├── models/
│   └── memo.dart             # 备忘录数据模型
├── main.dart                 # 应用入口，主题管理
├── memo_list_page.dart       # 主列表页（含搜索）
└── memo_edit_page.dart       # 编辑/新建页

android/                      # Android 原生配置
linux/                        # Linux 桌面原生配置
windows/                      # Windows 桌面原生配置
```

---

## 🧪 技术栈

| 技术 | 用途 |
|------|------|
| [Flutter](https://flutter.dev) | 跨平台 UI 框架 |
| [sqflite](https://pub.dev/packages/sqflite) | SQLite 数据库 |
| [path_provider](https://pub.dev/packages/path_provider) | 获取本地存储路径 |
| [intl](https://pub.dev/packages/intl) | 日期格式化 |
| [GitHub Actions](https://github.com/features/actions) | CI/CD 自动构建 |

---

## 🤝 贡献

目前是个人项目，但欢迎提出 Issue 或 Pull Request！

1. Fork 本仓库
2. 创建你的特性分支 (`git checkout -b feature/amazing`)
3. 提交你的修改 (`git commit -m 'Add some amazing feature'`)
4. 推送到分支 (`git push origin feature/amazing`)
5. 打开一个 Pull Request

---

## 📄 许可证

本项目采用 MIT 许可证 —— 详情请见 [LICENSE](LICENSE) 文件。

---

## 👤 作者

**zizong** · [GitHub](https://github.com/zizong)

---

## 🙏 致谢

- [Flutter](https://flutter.dev) 团队提供的优秀框架
- [GitHub Actions](https://github.com/features/actions) 提供的免费 CI/CD 服务
- 所有开源社区的贡献者

---

如果觉得这个项目对你有帮助，欢迎 ⭐ Star 支持一下！
