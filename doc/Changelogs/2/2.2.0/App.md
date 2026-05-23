# 📝 版本更新日志
## [v2.2.0] - 2026-05-23

### 🎯 重大更新
- 🔄 **数据库架构重构**: 从 Isar 迁移到 Hive，提升跨平台兼容性
- 🌐 **Web 平台支持**: 新增完整的 Web 平台适配

### ✨ 新增功能
- 📦 新增 Hive 数据库支持
- 🌐 Web 平台设备 ID 生成功能
- 🔌 新增 Web 适配层（io_web_stub）
- 🏭 新增 Repository 工厂模式（repository_factory）

### 🔄 功能优化
- 📐 优化 ScannerService 以支持 Web 平台
- 🔧 更新 main.dart 初始化逻辑，支持平台检测
- 📊 实现 Repository 抽象层，便于多平台适配

### 📦 依赖变更
- ➕ 新增: hive: ^2.2.3
- ➕ 新增: hive_flutter: ^1.1.0
- ➕ 新增: hive_generator: ^2.0.1
- ❌ 移除: isar: ^3.1.0+1
- ❌ 移除: isar_flutter_libs: ^3.1.0+1
- ❌ 移除: isar_generator: ^3.1.0+1
- 🔄 更新: pubspec.lock

### 🔧 技术改进
- 🏗️ 重构数据模型为 Hive 格式
- 🛡️ 移除 dart:io 依赖，提升 Web 兼容性
- 📊 Stream 监听保持不变，确保 API 兼容性
- 🔄 实现跨平台数据存储解决方案

### 📝 数据变更
- 📁 新增: hive_models.dart & hive_conversation_models.dart
- 📁 新增: models_web.dart & models_web_conversation.dart
- 📁 新增: web_repository.dart & web_conversation_repository.dart
- 📁 删除: history_models.dart & conversation_models.dart
- 📁 删除: math_mate_api_service.dart（不再需要）
