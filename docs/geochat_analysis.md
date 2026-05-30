# GeoChat 项目核心实现逻辑分析

## 📋 目录
- [核心架构概述](#核心架构概述)
- [自然语言转 GeoGebra 命令的流程](#自然语言转-geogebra-命令的流程)
- [LLM Prompt 设计详解](#llm-prompt-设计详解)
- [工具系统 (Tools)](#工具系统-tools)
- [GeoGebra 集成机制](#geogebra-集成机制)
- [关键代码实现](#关键代码实现)
- [对 MathMate 的借鉴价值](#对-mathmate-的借鉴价值)

---

## 🔍 核心架构概述

GeoChat 的整体架构可以分为以下几个层次：

```
┌─────────────────────────────────────────────────────────────┐
│                    用户界面层 (React/Next.js)               │
│  - 聊天输入框                                               │
│  - GeoGebra 画布                                            │
│  - 实时反馈                                                │
└────────────────────────┬────────────────────────────────────┘
                         │
┌────────────────────────▼────────────────────────────────────┐
│                 状态管理层 (Zustand Store)                   │
│  - 对话历史                                                 │
│  - 用户配置                                                 │
│  - 当前会话                                                 │
└────────────────────────┬────────────────────────────────────┘
                         │
┌────────────────────────▼────────────────────────────────────┐
│                    API 路由层 (Next.js API)                  │
│  /api/agent - LLM Agent 流式响应接口                         │
└────────────────────────┬────────────────────────────────────┘
                         │
┌────────────────────────▼────────────────────────────────────┐
│                  AI Agent 层 (LLM + Tools)                   │
│  - System Prompt (GeoGebra 专家角色)                         │
│  - Tool Calls (GeoGebra 操作工具)                           │
│  - 模型支持 (DeepSeek/OpenAI/Gemini)                        │
└────────────────────────┬────────────────────────────────────┘
                         │
┌────────────────────────▼────────────────────────────────────┐
│               GeoGebra Web API 层                            │
│  - JavaScript API (ggbApplet)                               │
│  - 命令执行引擎                                             │
│  - Canvas 渲染                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## 🔄 自然语言转 GeoGebra 命令的流程

### 完整工作流

```
用户输入: "画一个以 (2,3) 为圆心，半径为 5 的圆"
         ↓
    ┌─────────────────────────────────┐
    │ 1. 聊天页面接收输入              │
    │ (ChatPage.tsx)                  │
    └──────────────┬──────────────────┘
                   ↓
    ┌─────────────────────────────────┐
    │ 2. 发送到 /api/agent             │
    │ (POST 请求，包含模型参数)         │
    └──────────────┬──────────────────┘
                   ↓
    ┌─────────────────────────────────┐
    │ 3. LLM Agent 处理                │
    │ - 加载 System Prompt            │
    │ - 理解用户需求                    │
    │ - 调用工具                       │
    └──────────────┬──────────────────┘
                   ↓
         ┌─────────┴─────────┐
         ↓                   ↓
    ┌─────────────┐   ┌─────────────┐
    │ 状态感知     │   │ 执行命令     │
    │ getCanvasContext() │ executeGeoGebraCommand() │
    └─────────────┘   └──────┬──────┘
                             ↓
    ┌─────────────────────────────────┐
    │ 4. GeoGebra Web API 执行         │
    │ ggbApplet.asyncEvalCommandGetLabels() │
    └──────────────┬──────────────────┘
                   ↓
    ┌─────────────────────────────────┐
    │ 5. 返回结果给前端                 │
    │ 流式响应，实时更新               │
    └──────────────┬──────────────────┘
                   ↓
    ┌─────────────────────────────────┐
    │ 6. 前端渲染                      │
    │ Canvas 绘制几何图形               │
    └─────────────────────────────────┘
```

---

## 🎯 LLM Prompt 设计详解

### System Prompt 核心结构

从 `prompts.ts` 中可以看到，GeoChat 的 System Prompt 设计非常精妙：

```typescript
# Role: 专业 GeoGebra 几何专家 Agent (Logic & Action Optimized)

## 1. 角色定义
- 你是一个具备高度逻辑推理能力的 GeoGebra 几何助手
- 懂得几何逻辑，理解中国教师/学生的需求

## 2. 核心思维协议 (Critical Thinking Protocol)
1. 感知 (Perception): 获取当前画布状态
2. 推理 (Reasoning): 理解数学术语，构建几何步骤
3. 规划 (Planning): 拆解为原子级 GeoGebra 指令
4. 行动 (Action): 调用工具执行指令
5. 反思 (Reflection): 观察执行反馈，错误自愈

## 3. 工具调用准则
### 状态感知 (Blackboard Rule)
- 永远优先相信 getCanvasContext() 返回的数据
- 禁止猜测对象标签
- 活在当下：基于最新状态而非历史状态

### 精准执行 (Execution Precision)
- 执行命令前，必须使用 searchGeoGebraCommands 确认语法
- 优先使用几何约束而非硬编码坐标
- 原子化操作：一次仅执行一条逻辑指令

### 错误自愈 (Self-Healing)
- 若命令报错，立即：
  1. 调用 searchGeoGebraCommands 确认语法
  2. 调用 getCanvasContext 确认引用对象
  3. 修正后重新尝试执行
```

### Prompt 设计的精髓

#### ✅ **五阶段工作流**
```
第零阶段：梳理需求
  ↓
第一阶段：初始化与同步 (getCanvasContext)
  ↓
第二阶段：逻辑解析与说明 (向用户简述方案)
  ↓
第三阶段：增量绘图 (executeGeoGebraCommand)
  ↓
第四阶段：图形优化 (移除辅助对象，调整布局)
```

#### ✅ **几何约束优先原则**
```javascript
// ❌ 不推荐：硬编码坐标
Circle((2, 0), 5)

// ✅ 推荐：几何约束
Circle(O, A)  // O 是圆心，A 是圆上点
Midpoint(A, B)  // 使用中点约束
```

#### ✅ **动态关联性**
```javascript
// 所有关键点应该是可拖动的
// 确保参数范围和步长合理
// 支持动态几何演示
```

---

## 🛠️ 工具系统 (Tools)

GeoChat 定义了以下 **7 个核心工具**，全部通过 `tools.ts` 导出：

### 工具清单

| 工具名称 | 功能 | 输入参数 | 输出 |
|---------|------|---------|------|
| `searchGeoGebraCommands` | 搜索 GeoGebra 命令库 | `query: string` | 命令列表及语法 |
| `getCanvasContext` | 获取当前画布状态 | 无 | 元素列表、表达式列表、选中对象 |
| `executeGeoGebraCommand` | 执行 GeoGebra 命令 | `command: string` | 成功/失败、标签、错误信息 |
| `deleteGeoGebraObject` | 删除对象 | `label: string` | 是否成功 |
| `resetGeoGebra` | 重置画布 | 无 | 是否成功 |
| `setUndoPoint` | 设置撤销点 | 无 | 是否成功 |
| `undo` | 撤销操作 | 无 | 是否成功 |
| `setPerspective` | 切换视图模式 | `mode: string` (A/B/G/T) | 是否成功 |
| `getSelectedObjects` | 获取选中对象 | 无 | 选中对象列表 |

### 工具调用示例

```typescript
// 场景：用户说"画一个圆"
LLM 思考过程：
1. 需要先了解当前画布状态 → 调用 getCanvasContext()
2. 确定圆心和半径点 → 调用 executeGeoGebraCommand("O = (2, 3)")
3. 画圆 → 调用 executeGeoGebraCommand("Circle(O, A)")
```

---

## 🎨 GeoGebra 集成机制

### 初始化流程

```typescript
// use-geogebra.ts 中的初始化逻辑
1. 加载 GeoGebra JavaScript API
   window.GGBApplet = window.GGBApplet || {};

2. 创建 Applet 实例
   const ggbApp = new window.GGBApplet({
     appName: "classic",
     enable3d: true,
     showToolBar: true,
     // ...
   });

3. 注入到 DOM
   ggbApp.inject("geogebra-container");

4. 注册事件监听器
   ggbApi.registerClientListener((event) => {
     if (event.type === "select") {
       // 处理选择事件
     }
   });
```

### 命令执行机制

```typescript
// 执行 GeoGebra 命令
async function executeCommand(cmd: string) {
  // 使用 asyncEvalCommandGetLabels 获取执行结果
  const label = await window.ggbApplet.asyncEvalCommandGetLabels(cmd);
  
  // 检查是否有错误
  const lastCommandError = window.ggbLastCommandError;
  
  return {
    success: lastCommandError === "",
    label: label,
    error: lastCommandError
  };
}

// 示例命令
await executeCommand("A = (0, 0)");  // 创建点 A
await executeCommand("B = (5, 0)");  // 创建点 B
await executeCommand("Circle(A, B)");  // 创建圆
```

### Canvas 状态获取

```typescript
function getCanvasContext() {
  // 获取 XML 格式的画布状态
  const xmlText = window.ggbApplet.getXML();
  
  // 解析为 JSON
  const xmlJson = JSON.parse(xml2json(xmlText, { compact: true }));
  
  return {
    elements: xmlJson.geogebra.construction.element,
    expressions: xmlJson.geogebra.construction.expression
  };
}
```

---

## 📝 关键代码实现

### 1. API 路由 (route.ts)

```typescript
// /app/api/agent/route.ts
export async function POST(req: NextRequest) {
  // 1. 解析请求参数
  const { conversationId, messages, modelParams } = await req.json();
  
  // 2. 获取模型实例
  const model = getModel(
    modelParams.modelProvider,  // deepseek/openai/gemini
    modelParams.modelType,       // 模型类型
    modelParams.modelApiKey      // API Key
  );
  
  // 3. 配置流式响应
  const result = streamText({
    model,
    system: modelParams.modelPrompt,  // System Prompt
    messages: convertToModelMessages(messages),
    temperature: 0.6,
    stopWhen: stepCountIs(20),        // 最多 20 步推理
    toolChoice: "auto",
    tools: tools                      // 工具列表
  });
  
  // 4. 返回流式响应
  return result.toUIMessageStreamResponse();
}
```

### 2. 前端工具调用处理 (ChatPage.tsx)

```typescript
// 在 useChat 的 onToolCall 回调中处理工具调用
onToolCall({ toolCall }) {
  const { toolName, input } = toolCall;
  
  switch (toolName) {
    case "getCanvasContext":
      result = {
        selectedObjects: getSelectedObjects(),
        ...getCanvasContext()
      };
      break;
      
    case "executeGeoGebraCommand":
      result = await executeCommand(input.command);
      break;
      
    case "setPerspective":
      result = { success: setPerspective(input.mode) };
      break;
      
    // ... 其他工具
  }
  
  // 返回工具执行结果给 LLM
  addToolOutput({
    state: "output-available",
    toolCallId: toolCall.toolCallId,
    output: result
  });
}
```

### 3. GeoGebra Hook (use-geogebra.ts)

```typescript
// 暴露的核心接口
export interface GeoGebraCommands {
  isReady: boolean;
  rebuild: () => boolean;
  reset: () => void;
  executeCommand: (cmd: string) => Promise<{...}>;
  executeCommands: (cmds: string[]) => Promise<{...}[]>;
  getCanvasContext: () => Record<string, any>;
  setUndoPoint: () => boolean;
  undo: () => boolean;
  deleteGeoGebraObject: (label: string) => boolean;
  setPerspective: (mode: string) => boolean;
  evalLaTeX: (latex: string) => boolean;
  getPNGBase64: (scale: number, transparent: boolean, DPI: number) => string;
  getSelectedObjects: () => string[];
}
```

---

## 🎓 对 MathMate 的借鉴价值

### 1. **Prompt Engineering 策略**

GeoChat 的 Prompt 设计非常值得学习：

#### ✅ **五阶段思维协议**
```
感知 → 推理 → 规划 → 行动 → 反思
```

MathMate 可以借鉴这个框架来处理几何可视化：

```typescript
// MathMate 几何可视化五阶段
1. 感知：理解题目中的几何描述
2. 推理：抽取几何参数和约束条件
3. 规划：确定需要渲染的图元
4. 行动：调用渲染引擎生成图形
5. 反思：验证渲染结果是否符合预期
```

#### ✅ **错误自愈机制**
GeoChat 实现了 LLM 自动检测并修复 GeoGebra 命令错误的能力。

MathMate 可以实现类似机制：
- 检测渲染异常
- 自动调整参数
- 重新生成几何 JSON

### 2. **工具系统设计**

GeoChat 的工具系统是典型的 **MCP (Model Context Protocol)** 实现。

MathMate 可以借鉴：

```typescript
// MathMate 的工具系统
const tools = {
  // 几何相关
  createPoint: tool({...}),
  createLine: tool({...}),
  createCircle: tool({...}),
  createEllipse: tool({...}),
  createParabola: tool({...}),
  createHyperbola: tool({...}),
  
  // 可视化相关
  setAnimation: tool({...}),
  setConstraint: tool({...}),
  addSlider: tool({...}),
  
  // 数学计算相关
  solveEquation: tool({...}),
  calculateDistance: tool({...}),
  findIntersection: tool({...})
};
```

### 3. **增量绘图策略**

GeoChat 实现了 **增量绘图** - 不重绘整个画布，而是根据上下文添加新对象。

MathMate 的 GeometryPainter 可以借鉴：

```typescript
// 当前 MathMate 的方式
geometryPainter.clear();
geometryPainter.render(json);  // 每次都重新渲染

// 可以改进为
if (!geometryPainter.hasContext()) {
  geometryPainter.initialize();
}
geometryPainter.addObjects(json.newElements);  // 增量添加
geometryPainter.updateObjects(json.updatedElements);  // 更新
```

### 4. **多模型协作架构**

GeoChat 支持 **DeepSeek / OpenAI / Gemini** 多种模型。

MathMate 可以扩展为：

```typescript
// MathMate 的多模型协作
const modelPipeline = {
  ocr: "VolcEngine",           // 题目识别
  solver: "DeepSeek",          // 数学推理
  geometryGenerator: "DeepSeek", // 几何 JSON 生成
  chat: "Qwen-PLUS"           // 对话助手
};
```

### 5. **实时反馈机制**

GeoChat 实现了流式响应，每执行 1-3 条命令就反馈一次。

MathMate 可以实现类似机制：

```typescript
// MathMate 实时反馈
async function* solveProblem(image: Image) {
  // 1. OCR 识别
  yield { status: "recognizing", progress: 20 };
  
  // 2. 数学推理
  yield { status: "solving", progress: 50 };
  
  // 3. 几何生成
  yield { status: "generating_geometry", progress: 80 };
  
  // 4. 完成
  yield { status: "completed", progress: 100 };
}
```

---

## 🔑 核心设计原则总结

### GeoChat 的成功要素

1. **清晰的角色定义** - System Prompt 明确定义了"GeoGebra 几何专家"角色
2. **严格的思维协议** - 五阶段思维确保逻辑正确
3. **状态感知优先** - 永远相信画布状态，不猜测
4. **原子化操作** - 每次仅执行一条逻辑指令，便于错误追踪
5. **错误自愈能力** - 自动检测并修复错误
6. **几何约束优先** - 使用约束而非硬编码，保持动态关联
7. **增量绘图** - 根据上下文增量添加对象

### MathMate 可以借鉴的设计

1. **Prompt Engineering**
   - 设计专门的"数学几何可视化专家"角色
   - 实现五阶段思维协议
   - 添加错误检测和自愈机制

2. **工具系统**
   - 实现 MCP 协议的工具调用
   - 支持更多数学操作工具
   - 实现增量渲染

3. **用户体验**
   - 流式响应，实时反馈
   - 分步骤展示解题过程
   - 支持交互式探索

4. **代码架构**
   - 分离 LLM 逻辑和渲染逻辑
   - 抽象 GeoGebra API
   - 支持多模型协作

---

## 📚 参考文件

- **Prompt 定义**: [core/agent/prompts.ts](file:///D:/projects/add/GeoChat/next/core/agent/prompts.ts)
- **工具系统**: [server/core/agent/tools.ts](file:///D:/projects/add/GeoChat/next/server/core/agent/tools.ts)
- **API 路由**: [app/api/agent/route.ts](file:///D:/projects/add/GeoChat/next/app/api/agent/route.ts)
- **聊天页面**: [app/chat/page.tsx](file:///D:/projects/add/GeoChat/next/app/chat/page.tsx)
- **GeoGebra Hook**: [client/hooks/use-geogebra.ts](file:///D:/projects/add/GeoChat/next/client/hooks/use-geogebra.ts)
