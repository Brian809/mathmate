# MathMate — 智能数学学习助手

<p align="center">
  <img src="https://raw.githubusercontent.com/mzk-C4/Matemate-website/main/images/poster.png" alt="MathMate" width="500">
</p>

<p align="center">
  <strong>AI 驱动 · 动态可视化 · 一站式数学学习</strong>
</p>

<p align="center">
  <a href="https://www.bilibili.com/video/BV1EfLJ6bEnw">🎬 演示视频</a> ·
  <a href="https://mathmate.top">🌐 官网</a> ·
  <a href="https://github.com/mzk-C4/mathmate">📂 GitHub</a> ·
  <a href="https://pan.baidu.com/s/1aAbJhw9xCIevHPjnrJW-8w?pwd=emu9">📦 下载 APK</a>
</p>

<p align="center">
  <a href="https://www.bilibili.com/video/BV1EfLJ6bEnw" target="_blank">
    <img src="https://raw.githubusercontent.com/mzk-C4/Matemate-website/main/images/real-scene.png" alt="MathMate 演示" width="600">
  </a>
</p>

<p align="center">👆 点击图片观看演示视频</p>

---

**MathMate** 是一款功能全面的 AI 数学学习应用，基于 Flutter 构建，支持 Android、iOS 和 Web。以"拍照搜题 → AI 解题 → 几何可视化"为核心流程，辅以手写笔记、AI 对话、数学工具箱、视频推荐等学习场景。

## 核心功能

### 拍照搜题
拍照或从相册选取数学题目，AI 自动识别公式、求解并生成分步解析。支持图像裁剪与增强预处理（自动透视校正、自适应锐化、背景二值化）。

### 几何可视化（自研引擎）
题目中的几何图形自动渲染为可交互的 Canvas 图形（点、线、圆、椭圆、抛物线、双曲线），支持缩放拖拽和动点交互。基于自研 **GeometryJSON 协议**——AI 输出结构化 JSON，纯 Dart Canvas 引擎渲染为 60fps 交互式图形。解析失败自动重试一次。

### AI 对话助手（蓝心助手）
流式聊天解答数学问题，支持 Markdown + LaTeX 公式实时渲染，含深度思考链展示。支持多模型切换（DeepSeek / Qwen），从主页搜索框 Hero 过渡动画进入对话。

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
- **公式可视化分析**：对每个识别出的公式，一键触发 AI 解释 + 交互式 WebView 可视化（Plotly.js / Chart.js）
- **笔记管理**：支持保存/加载/导出文本，与打字笔记统一管理

### 打字笔记
基于 flutter_quill 的富文本编辑器，支持 LaTeX 公式插入、图片、PDF 标注。

### 视频推荐
基于 AI 推荐 + 本地关键词匹配的 B 站数学视频推荐，支持按年级/模块筛选，历史记录加权排序。大学阶段暂不展示视频推荐。

### 个人中心
- **年级选择**：小学 1-6 年级 / 初中 / 高中 / 大学（含研究生），影响内容推荐
- **用户资料**：昵称、头像、年级、个性签名
- **主题切换**：亮色 / 暗色 / 跟随系统
- **搜题历史**：本地搜索记录浏览与清空

## 产品截图

<table>
  <tr>
    <td align="center"><b>应用首页</b></td>
    <td align="center"><b>拍照识别</b></td>
    <td align="center"><b>AI 解题</b></td>
  </tr>
  <tr>
    <td><img src="https://raw.githubusercontent.com/mzk-C4/Matemate-website/main/images/%E5%BE%AE%E4%BF%A1%E5%9B%BE%E7%89%87_20260507224931_199_31.jpg" width="250"></td>
    <td><img src="https://raw.githubusercontent.com/mzk-C4/Matemate-website/main/images/%E5%BE%AE%E4%BF%A1%E5%9B%BE%E7%89%87_20260508204749_218_31.jpg" width="250"></td>
    <td><img src="https://raw.githubusercontent.com/mzk-C4/Matemate-website/main/images/%E5%BE%AE%E4%BF%A1%E5%9B%BE%E7%89%87_20260508204844_225_31.jpg" width="250"></td>
  </tr>
  <tr>
    <td align="center"><b>AI 对话助手</b></td>
    <td align="center"><b>手写笔记</b></td>
    <td align="center"><b>数学工具箱</b></td>
  </tr>
  <tr>
    <td><img src="https://raw.githubusercontent.com/mzk-C4/Matemate-website/main/images/%E5%BE%AE%E4%BF%A1%E5%9B%BE%E7%89%87_20260507224940_209_31.jpg" width="250"></td>
    <td><img src="https://raw.githubusercontent.com/mzk-C4/Matemate-website/main/images/%E5%BE%AE%E4%BF%A1%E5%9B%BE%E7%89%87_20260508201708_217_31.png" width="250"></td>
    <td><img src="https://raw.githubusercontent.com/mzk-C4/Matemate-website/main/images/%E5%BE%AE%E4%BF%A1%E5%9B%BE%E7%89%87_20260507224932_201_31.jpg" width="250"></td>
  </tr>
</table>

## 技术架构

### AI 多模型协作流水线

应用核心流程由 `MathPipelineService` 串联，三大 AI 模型各司其职：

| 阶段 | 服务 | AI 模型 | 输入 → 输出 |
|------|------|---------|-------------|
| OCR 识别 | `OcrService` | 火山引擎 多模态 | 拍照图片 → Markdown + LaTeX |
| 解题推理 | `SolverService` | DeepSeek | 数学题文本 → 分步解题 Markdown |
| 几何可视化 | `VisualizationService` | DeepSeek | 解题结果 → GeometryJSON |
| AI 对话 | `ChatStreamService` | Qwen-PLUS | 多轮上下文 → SSE 流式 Markdown |
| 手写 OCR | `HandwritingOcrService` | 火山引擎 | 笔迹图片 → LaTeX 公式 |
| 公式分析 | `FormulaAnalysisService` | 火山引擎 | 数学公式 → 分析解释 |
| 视频推荐 | `VideoRecommendationService` | DeepSeek | 搜索历史 → B 站视频列表 |

### 自研可视化引擎

- **GeometryJSON 协议**：LLM 友好的结构化几何描述语言（viewport + elements + constraints）
- **GeometryPainter**：纯 Dart + Flutter Canvas，零 WebView 依赖，原生 60fps
- **GeometryValidator**：AI 输出校验与容错（SafeJsonParser 处理 Infinity / NaN 等非标准值）
- **Constraint Solver**：动点约束求解（投影到圆弧/线段/曲线），支持手势拖拽交互

### 数据层

- **Hive**：本地 NoSQL 数据库（搜题历史、AI 对话记录）—— v2.2.0 从 Isar 迁移以支持 Web
- **SharedPreferences**：键值对持久化（用户资料、主题、年级等设置）
- **纯本地架构**：零服务器成本、数据完全本地化、离线可用

## 技术栈

### 核心框架
| 技术 | 版本 | 用途 |
|------|------|------|
| Flutter SDK | Dart ^3.11.3 | 跨平台 UI 框架（Android / iOS / Web / Desktop） |
| http | ^1.1.0 | HTTP 客户端，调用 AI API |
| flutter_dotenv | ^5.2.1 | .env 文件加载 API 密钥 |

### AI 与渲染
| 技术 | 版本 | 用途 |
|------|------|------|
| DeepSeek API | deepseek-chat | 数学推理、解题、可视化 JSON 生成、视频推荐 |
| 火山引擎 | 多模态模型 | OCR 识别（手写 + 印刷）、公式分析 |
| Qwen-PLUS | via DashScope | 流式 AI 对话（SSE） |
| flutter_math_fork | ^0.7.2+1 | LaTeX / MathML 公式渲染 |
| flutter_markdown_plus | ^1.0.7 | Markdown 渲染（代码高亮 + LaTeX） |

### 数据存储
| 技术 | 版本 | 用途 |
|------|------|------|
| Hive | ^2.2.3 | 本地 NoSQL 数据库（搜题历史、对话记录） |
| shared_preferences | ^2.5.3 | 键值对持久化（主题、年级、设置） |
| path_provider | ^2.1.5 | 跨平台文件路径管理 |

### UI 与交互
| 技术 | 版本 | 用途 |
|------|------|------|
| webview_flutter | ^4.10.0 | 内嵌 WebView（GeoGebra、KaTeX、B 站视频） |
| flutter_quill | ^11.5.0 | 富文本编辑器 |
| image_picker | ^1.0.0 | 相机拍照 / 相册选取 |
| image | ^4.5.4 | 图像处理（裁剪、缩放、预处理） |
| pdf | ^3.11.3 | PDF 文档生成 |
| file_picker | ^8.0.0 | 文件选择器（PDF 导入） |
| cached_network_image | ^3.4.1 | 网络图片缓存 |
| url_launcher | ^6.3.1 | 打开外部链接 |
| share_plus | ^10.1.4 | 系统分享 |
| permission_handler | ^11.3.1 | 运行时权限管理 |
| device_info_plus | ^11.0.0 | 设备信息（设备 ID） |
| open_file | ^3.5.10 | 打开本地文件 |

### 内嵌第三方资源
| 资源 | 协议 | 用途 |
|------|------|------|
| GeoGebra Web3D | GPL v3 | 离线数学工具套件（6 种工具） |
| KaTeX | MIT | LaTeX 公式渲染（WebView） |
| PDF.js | Apache 2.0 | Mozilla PDF 渲染引擎（查看与标注） |
| Plotly.js v2.27.0 | MIT | 交互式数据可视化（CDN） |
| Chart.js | MIT | HTML5 Canvas 图表（CDN） |

### 开发工具链
| 技术 | 版本 | 用途 |
|------|------|------|
| build_runner | ^2.4.13 | Dart 代码生成 |
| hive_generator | ^2.0.1 | Hive TypeAdapter 生成 |
| flutter_launcher_icons | ^0.14.2 | 多平台图标生成 |
| flutter_lints | ^6.0.0 | Lint 规则 |

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
│   ├── app_logger.dart                    # 应用日志（条件导出）
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
│   ├── hive_models.g.dart                 # Hive 代码生成
│   ├── hive_conversation_models.dart      # Hive 对话模型
│   ├── hive_conversation_models.g.dart    # Hive 对话代码生成
│   ├── video_recommendations.dart         # 视频推荐数据
│   ├── video_resources.dart               # 分级视频资源库
│   ├── repository_factory.dart            # 条件导出（适配 Web/Native）
│   ├── web_repository.dart                # Web 端数据仓库
│   └── web_conversation_repository.dart   # Web 端对话仓库
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
| `result_page.dart` | 解题结果页（旧版） |
| `beautiful_result_page.dart` | 解题结果展示 + 内联可视化 |
| `visualization_page.dart` | 全屏几何可视化 |
| `geogebra_page.dart` | GeoGebra 工具箱 |
| `chat_page.dart` | AI 对话（流式、Markdown、思考链） |
| `notes_page.dart` | 笔记列表 |
| `note_editor_page.dart` | 打字笔记编辑器 |
| `note_handwriting_editor_page.dart` | 手写笔记编辑器 |
| `handwriting_page.dart` | 独立手写页 |
| `history_list_page.dart` | 搜题历史 |
| `pdf_viewer_page.dart` | PDF 查看与标注 |
| `profile_page.dart` | 个人中心 |
| `account_settings_page.dart` | 账户设置（个人资料/账号安全/通知） |
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
#   DEEPSEEK_API_KEY=sk-your-deepseek-key
#   DEEPSEEK_MODEL_ID=deepseek-chat
#   DEEPSEEK_BASE_URL=https://api.deepseek.com/chat/completions
#   VIVO_API_KEY=sk-your-qwen-key
#   VIVO_MODEL_ID=qwen-plus
#   VIVO_BASE_URL=https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions
#   VOLC_API_KEY=your-volc-api-key
#   VOLC_MODEL_ID=your-model-id
#   VOLC_BASE_URL=https://ark.cn-beijing.volces.com/api/v3/chat/completions

# 安装依赖
flutter pub get

# 生成代码（Hive TypeAdapter）
flutter pub run build_runner build

# 运行
flutter run

# 构建 APK
flutter build apk --debug

# 构建 Web
flutter build web
```

## 开源参考

MathMate 的开发过程中学习并参考了以下优秀开源项目：

| 项目 | 来源 | 参考价值 |
|------|------|----------|
| [ToRA](https://github.com/microsoft/ToRA) | Microsoft Research | 工具集成推理，启发未来"工具增强推理"方向 |
| [DeepSeek-Math](https://github.com/deepseek-ai/DeepSeek-Math) | DeepSeek AI | 数学推理模型，直接启发选择 DeepSeek 作为核心引擎 |
| [Mather](https://github.com/Green-Wood/Mather) | Community | 知识库架构和 API 设计参考 |
| [AutoScaler](https://github.com/Green-Wood/AutoScaler) | SCUT | 手写数学表达式识别算法参考 |
| [awesome-math](https://github.com/rossning92/awesome-math) | Community | 分级知识点体系与内容结构参考 |
| [GeoGebra](https://www.geogebra.org/) | Open Source (GPL) | 离线嵌入的数学可视化工具 |
| [NextChat](https://github.com/ChatGPTNextWeb/NextChat) | ChatGPTNextWeb | 流式对话 UI 设计、Markdown 渲染方案参考 |

## 相关链接

- **官网**：[mathmate.top](https://mathmate.top)
- **项目展示页**：[GitHub Pages](https://mzk-c4.github.io/Matemate-website/)
- **演示视频**：[Bilibili](https://www.bilibili.com/video/BV1EfLJ6bEnw)
- **源代码**：[GitHub](https://github.com/mzk-C4/mathmate)

## 下载

- **Android**：[百度网盘](https://pan.baidu.com/s/1aAbJhw9xCIevHPjnrJW-8w?pwd=emu9)
- **iOS**：即将上架

## 更新日志

详见 [doc/Changelogs/](doc/Changelogs/)

## 协议

MIT
