# MathMate — 智能数学学习助手

**MathMate** 是一款功能全面的 AI 数学学习应用，基于 Flutter 构建，支持 Android 和 iOS。以"拍照搜题 → AI 解题 → 几何可视化"为核心流程，辅以手写笔记、AI 对话、视频推荐等学习场景。

## 核心功能

### 拍照搜题
拍照或从相册选取数学题目，AI 自动识别公式、求解并生成分步解析。支持图像裁剪与增强预处理。

### 几何可视化
题目中的几何图形自动渲染为可交互的 Canvas 图形（点、线、圆、椭圆、抛物线、双曲线），支持缩放拖拽。空场景合法（无几何图形时降级为纯文字解析）。解析失败自动重试一次。

### AI 对话助手
流式聊天解答数学问题，支持 Markdown + LaTeX 公式实时渲染，含深度思考链展示。支持从主页搜索框 Hero 过渡动画进入对话，文字自动填入。

### 数学工具箱
集成 GeoGebra 离线版（WebView），提供科学计算器、几何画板、函数绘图、3D 视图、尺规作图、概率模型六种工具。

### 手写笔记
- **多纸张背景**：空白 / 横线 / 网格，间距可调
- **笔画平滑**：Catmull-Rom 样条插值消除折线锯齿
- **真橡皮擦**：检测笔迹与擦除路径交集，精确删除被擦到的笔画
- **多色画笔**：7 种颜色 + 细/中/粗三种笔宽
- **手势操作**：双指缩放、单指平移、左右滑动翻页、弹性回弹
- **手写识别**：AI OCR 将笔迹转为 LaTeX 公式文本
- **可拖动识别面板**：支持 12%/35%/75% 三档吸附、上下拖动、关闭/重新打开
- **公式可视化分析**：对每个识别出的公式，一键触发 AI 解释 + 交互式 WebView 可视化
- **笔记管理**：支持保存/加载/导出文本，与打字笔记统一管理

### 打字笔记
基于 flutter_quill 的富文本编辑器，支持 LaTeX 公式插入、图片、PDF 标注。

### 视频推荐
基于 AI 推荐 + 本地关键词匹配的 B 站数学视频推荐，支持按年级/模块筛选，历史记录加权排序。大学阶段暂不推荐视频。

### 个人中心
- **年级选择**：小学 1-6 年级 / 初中 / 高中 / 大学（含研究生），影响内容推荐
- **用户资料**：昵称、头像、年级、个性签名，SharedPreferences 持久化
- **主题切换**：亮色 / 暗色 / 跟随系统
- **搜题历史**：本地搜索记录浏览与清空

## 技术栈

| 技术 | 用途 |
|------|------|
| Flutter 3.x (Dart ^3.11.3) | 跨平台 UI 框架 |
| DeepSeek / 火山引擎 API | AI 大模型：OCR 识别、解题推理、可视化生成、公式分析、视频推荐 |
| Hive | 高性能本地 NoSQL 数据库（搜题历史、对话记录） |
| SharedPreferences | 键值对持久化（用户资料、主题、年级等设置） |
| GeoGebra (WebView) | 离线数学可视化工具 |
| KaTeX / flutter_math_fork | 数学公式渲染 |
| flutter_quill | 富文本编辑 |
| webview_flutter | 内嵌 WebView（公式可视化、B 站视频） |
| Catmull-Rom 样条 | 手写笔画平滑插值 |

## 项目结构

```
lib/
├── main.dart                              # 应用入口、主页框架、底部导航、Hero 过渡动画
├── models/
│   ├── pipeline_models.dart               # OCR/解题/可视化结果模型
│   ├── pipeline_stage.dart                # 流水线阶段枚举
│   └── user_profile.dart                  # 用户资料模型
├── services/
│   ├── math_pipeline_service.dart         # 核心流水线编排 (OCR→解题→可视化)
│   ├── ocr_service.dart                   # 图片 OCR 服务
│   ├── solver_service.dart                # AI 解题服务
│   ├── visualization_service.dart         # 几何可视化生成（含重试逻辑）
│   ├── formula_analysis_service.dart      # 单公式 AI 分析
│   ├── handwriting_ocr_service.dart       # 手写 OCR 识别
│   ├── deepseek_service.dart              # DeepSeek API 客户端
│   ├── chat_stream_service.dart           # 流式聊天响应
│   ├── vivo_chat_service.dart             # Vivo AI 聊天服务
│   ├── volc_ai_client_service.dart        # 火山引擎 AI 客户端
│   ├── model_service.dart                 # AI 模型配置管理
│   ├── video_recommendation_service.dart  # 视频推荐服务
│   ├── scanner_service.dart               # 拍照/相册服务
│   ├── theme_service.dart                 # 主题模式管理
│   ├── user_profile_service.dart          # 用户资料服务
│   ├── katex_pdf_service.dart             # KaTeX 转 PDF
│   ├── latex_compiler.dart                # LaTeX 本地编译
│   └── prompts/                           # AI 提示词模板
│       ├── ocr_prompt.dart
│       ├── solve_prompt.dart
│       └── visualization_prompt.dart
├── data/
│   ├── history_repository.dart            # 搜题历史持久化
│   ├── conversation_repository.dart       # 对话记录持久化
│   ├── hive_models.dart                   # Hive 数据模型
│   ├── video_recommendations.dart         # 视频推荐数据
│   └── video_resources.dart               # 分级视频资源库
├── visualization/
│   ├── geometry_painter.dart              # Canvas 几何绘制
│   ├── geometry_validator.dart            # 几何 JSON 校验
│   ├── response_extractor.dart            # AI 响应解析
│   ├── models.dart                        # 几何数据模型
│   └── safe_json_parser.dart              # 安全 JSON 解析
├── pages/
│   ├── chat_home_page.dart                # AI 对话首页
│   ├── calculator_page.dart               # 科学计算器
│   ├── video_player_page.dart             # 视频播放器
│   └── flash_text_demo_page.dart          # 文本动画演示
├── scanner/
│   └── enhanced_crop_page.dart            # 图片裁剪
├── theme/
│   └── app_theme.dart                     # 亮色/暗色主题
└── widgets/
    ├── flash_text.dart                    # 文本动画组件
    └── ring_color_picker.dart             # 环形颜色选择器
```

### 功能页面一览

| 文件 | 功能 |
|------|------|
| `main.dart` | 主界面、底部导航（题目/笔记/我的）、Hero 动画 |
| `grade_selection_page.dart` | 年级选择（小学→大学） |
| `tutorial_page.dart` | 新手引导 |
| `recognizer_page.dart` | 拍照识别入口 |
| `beautiful_result_page.dart` | 解题结果展示 + 内联可视化 |
| `result_page.dart` | 结果页（旧版） |
| `visualization_page.dart` | 全屏几何可视化 |
| `geogebra_page.dart` | GeoGebra 工具箱 |
| `chat_page.dart` | AI 对话（流式、Markdown、思考链） |
| `notes_page.dart` | 笔记列表 |
| `note_editor_page.dart` | 打字笔记编辑器 |
| `note_handwriting_editor_page.dart` | 手写笔记编辑器 |
| `handwriting_page.dart` | 独立手写页 |
| `note_model.dart` | 笔记数据模型 |
| `history_list_page.dart` | 搜题历史 |
| `pdf_viewer_page.dart` | PDF 查看与标注 |
| `profile_page.dart` | 个人中心 |
| `account_settings_page.dart` | 账户设置 |
| `edit_profile_page.dart` | 编辑个人资料 |
| `help_support_page.dart` | 帮助与支持 |
| `about_mathmate_page.dart` | 关于应用 |

## 运行项目

```bash
# 克隆项目
git clone https://github.com/mzk-C4/mathmate.git
cd mathmate

# 配置环境变量
cp .env.example .env
# 编辑 .env 填入 API Key:
#   VOLC_API_KEY=your_volcano_engine_api_key
#   VOLC_MODEL_ID=your_model_id
#   VOLC_BASE_URL=https://ark.cn-beijing.volces.com/api/v3/chat/completions

# 安装依赖
flutter pub get

# 生成代码
flutter pub run build_runner build

# 运行
flutter run

# 构建 APK
flutter build apk --debug
```

## 下载

- **Android**: 即将上架
- **iOS**: 即将上架

## 更新日志

详见 [doc/Changelogs/](doc/Changelogs/)

## 协议

MIT
