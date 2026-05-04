# MathMate - 智能数学学习助手 📐📊

**MathMate** 是一款功能丰富的智能数学学习移动应用，基于 Flutter 构建，支持 Android 和 iOS 双平台。

## ✨ 核心功能

- **📸 拍照搜题** - 快速识别数学题目并获取解答
- **✏️ 手写识别** - 支持多种纸张背景（空白、横线、网格）的手写笔记
- **📝 智能笔记** - 集成 GeoGebra 数学工具的笔记编辑功能
- **📄 PDF 查看** - 内置数学文档查看器
- **💬 AI 助手** - 智能聊天解答数学问题
- **🎨 可视化学习** - GeoGebra 3D 计算器、科学计算器、概率计算器

## 🛠️ 技术栈

| 技术 | 说明 |
|------|------|
| Flutter | 跨平台移动开发框架 |
| Supabase | 后端即服务 (实时聊天、数据存储) |
| Isar | 高性能本地数据库 |
| GeoGebra | 世界领先的数学可视化工具 |
| KaTeX | 快速数学公式渲染 |

## 📁 项目结构

```
lib/
├── main.dart                    # 应用入口
├── chat_page.dart              # AI 聊天页面
├── handwriting_page.dart       # 手写识别
├── notes_page.dart            # 笔记列表
├── note_handwriting_editor_page.dart  # 手写笔记编辑器
├── pdf_viewer_page.dart       # PDF 查看器
├── geogebra_page.dart         # GeoGebra 集成
├── recognizer_page.dart       # 题目识别
├── result_page.dart           # 结果展示
└── ...
```

## 🚀 运行项目

```bash
# 克隆项目
git clone https://github.com/mzk-C4/mathmate.git

# 安装依赖
flutter pub get

# 运行应用
flutter run
```

## 📱 下载应用

- **Android**: 即将发布
- **iOS**: 即将发布

## 📄 开源协议

本项目采用 MIT 协议开源。

---

## 📝 更新日志

查看完整更新日志：[Changelogs](doc/Changelogs/)