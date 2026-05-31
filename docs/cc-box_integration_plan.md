# CC-Box 与 CC-Switch 集成方案

## 📋 目录
- [项目概述](#项目概述)
- [现有架构分析](#现有架构分析)
- [集成目标](#集成目标)
- [技术方案](#技术方案)
- [实施步骤](#实施步骤)
- [核心功能迁移](#核心功能迁移)
- [UI/UX 设计](#uiux-设计)
- [注意事项](#注意事项)

---

## 🎯 项目概述

### CC-Box (新仓库)
**位置**: `D:\projects\add\cc-box`  
**技术栈**: Go + Wails + Svelte  
**核心功能**:
- CLI 工具 + GUI 桌面应用
- 加密备份 Claude Code 配置 (`~/.claude/`)
- WebDAV 存储同步
- 版本历史和回滚
- Claude 二进制管理
- 三路合并冲突解决

### CC-Switch (现有应用)
**位置**: `C:\Users\MZK\AppData\Local\Programs\CC Switch\cc-switch.exe`  
**技术栈**: (需要逆向分析)  
**核心功能**:
- Claude Code 配置管理
- GUI 界面
- (其他功能待分析)

---

## 🔍 现有架构分析

### CC-Box 架构

```
┌─────────────────────────────────────────────────────────────┐
│                     用户界面层 (Svelte)                      │
│  Dashboard │ Files │ Binaries │ Projects │ History │ Settings │
└────────────────────────┬────────────────────────────────────┘
                         │
┌────────────────────────▼────────────────────────────────────┐
│                    Wails 绑定层                              │
│  frontend_regression_test │ e2e_virtual_test │ onboarding   │
└────────────────────────┬────────────────────────────────────┘
                         │
┌────────────────────────▼────────────────────────────────────┐
│                    Go 后端逻辑层                             │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────────────┐   │
│  │   CLI 模块  │ │  Binary 模块 │ │    GUI 模块         │   │
│  │  push/pull  │ │  install    │ │  dashboard/files    │   │
│  └─────────────┘ └─────────────┘ └─────────────────────┘   │
└────────────────────────┬────────────────────────────────────┘
                         │
┌────────────────────────▼────────────────────────────────────┐
│                    Core 共享模块                             │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────────┐   │
│  │  Crypto  │ │ Snapshot │ │  Object   │ │    WebDAV    │   │
│  │ (加密)   │ │ (快照)   │ │ (对象存储) │ │   (存储)     │   │
│  └──────────┘ └──────────┘ └──────────┘ └──────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

### 核心模块说明

| 模块 | 路径 | 功能 |
|------|------|------|
| **crypto** | `core/crypto/` | Argon2id 密钥派生 + AES-256-GCM 加密 |
| **snapshot** | `core/snapshot/` | 文件扫描、快照创建、差异计算 |
| **object** | `core/object/` | 内容寻址对象存储、去重 |
| **webdav** | `core/webdav/` | WebDAV 客户端、ETag、CAS |
| **binary** | `core/binary/` | Claude 二进制安装、备份、切换 |
| **sync** | `core/sync/` | 三路合并、冲突检测 |
| **cli** | `cli/` | 命令行工具 (Cobra) |
| **gui** | `gui/` | 桌面 GUI 应用 (Wails + Svelte) |

---

## 🎯 集成目标

### 短期目标 (1-2 周)
1. ✅ 将 CC-Box 的 CLI 功能集成到 CC-Switch
2. ✅ 复用 CC-Box 的加密/解密模块
3. ✅ 复用 CC-Box 的 WebDAV 同步逻辑
4. ✅ 迁移 CC-Box 的版本历史和回滚功能

### 中期目标 (1 个月)
1. ✅ 将 CC-Box 的 GUI 界面集成到 CC-Switch
2. ✅ 实现跨平台支持
3. ✅ 优化用户体验

### 长期目标 (2-3 个月)
1. ✅ 开发 CC-Switch 独有的高级功能
2. ✅ 建立开发者社区
3. ✅ 支持更多云存储提供商

---

## 🛠️ 技术方案

### 方案一：渐进式集成 (推荐)

**思路**: 
- 保留 CC-Switch 的 UI 和核心逻辑
- 逐步替换 CC-Switch 的底层模块为 CC-Box 的实现
- 最后统一 UI 风格

**优点**:
- 风险低，可逐步验证
- 保留 CC-Switch 的已有用户习惯
- 便于回滚

**缺点**:
- 集成周期较长
- 需要维护两套代码一段时间

### 方案二：完全迁移

**思路**:
- 以 CC-Box 为基础进行开发
- 重新设计 UI，兼容 CC-Switch 的操作习惯
- 一次性替换所有模块

**优点**:
- 代码结构清晰
- 便于后续维护和升级

**缺点**:
- 风险较高
- 可能改变用户习惯

### 方案三：混合架构

**思路**:
- CC-Box 作为核心库 (Go Module)
- CC-Switch 作为 UI Shell
- 通过 IPC/FFI 调用 CC-Box 功能

**优点**:
- 职责分离清晰
- 便于模块化测试

**缺点**:
- 需要处理跨语言调用
- 复杂度较高

---

## 📝 实施步骤

### 第一阶段：代码分析 (1-2 天)

#### 1.1 分析 CC-Switch
```bash
# 反编译或查看 CC-Switch 源码（如果有）
# 分析其核心功能和架构

主要模块：
- 配置管理
- Claude Code 交互
- 用户界面
- 数据存储
```

#### 1.2 分析 CC-Box 核心模块
```bash
# 重点分析以下模块：

core/crypto/      # 加密模块 - 必须复用
core/snapshot/    # 快照模块 - 必须复用
core/object/       # 对象存储 - 必须复用
core/webdav/      # WebDAV - 必须复用
core/binary/      # 二进制管理 - 根据需求
core/sync/        # 同步模块 - 根据需求
```

---

### 第二阶段：接口设计 (2-3 天)

#### 2.1 设计统一 API

```go
// pkg/claude_sync/claude_sync.go

package claude_sync

type SyncConfig struct {
    WebDAVURL      string
    WebDAVUsername string
    WebDAVPassword string
    EncryptionKey  string  // Argon2id 派生的密钥
    DeviceName     string
}

type ClaudeSync struct {
    config *SyncConfig
    snapshot *snapshot.Manager
    object *object.Store
    webdav *webdav.Client
}

func NewClaudeSync(cfg *SyncConfig) (*ClaudeSync, error)
func (cs *ClaudeSync) Init() error
func (cs *ClaudeSync) Push() error
func (cs *ClaudeSync) Pull() error
func (cs *ClaudeSync) Sync() error
func (cs *ClaudeSync) Status() (*SyncStatus, error)
func (cs *ClaudeSync) Log() ([]Snapshot, error)
func (cs *ClaudeSync) Revert(snapshotID string) error
func (cs *ClaudeSync) Conflicts() ([]Conflict, error)
func (cs *ClaudeSync) ResolveConflict(conflictID string, resolution Resolution) error
```

#### 2.2 设计二进制管理 API

```go
// pkg/claude_binary/claude_binary.go

package claude_binary

type BinaryManager struct {
    platform string
    config   *PathConfig
}

type ClaudeVersion struct {
    Version   string
    Source    string  // "official" | "github" | "webdav"
    Installed bool
    Path      string
    Size      int64
    Hash      string
}

func (bm *BinaryManager) List() ([]ClaudeVersion, error)
func (bm *BinaryManager) Install(source string, version string) error
func (bm *BinaryManager) Switch(version string) error
func (bm *BinaryManager) Backup() error
func (bm *BinaryManager) Uninstall(version string) error
```

---

### 第三阶段：核心功能迁移 (5-7 天)

#### 3.1 迁移加密模块

**CC-Box 核心实现**:

```go
// core/crypto/keygen.go
func GenerateKey(password string, salt []byte) ([]byte, error) {
    // Argon2id 参数
    params := &argon2.Params{
        Memory:      64 * 1024, // 64 MB
        Iterations:  3,
        Parallelism: 4,
        HashLen:    32,        // 256 bits
        SaltLen:    16,        // 128 bits
    }
    
    key := argon2.IDKey([]byte(password), salt, params.Time, params.Memory, params.Parallelism, params.KeyLen)
    return key, nil
}

// core/crypto/secure_file.go
func Encrypt(data []byte, key []byte) ([]byte, error) {
    // 生成随机 IV
    nonce := make([]byte, 12)
    if _, err := rand.Read(nonce); err != nil {
        return nil, err
    }
    
    // AES-256-GCM 加密
    cipher, err := aes.NewCipher(key)
    if err != nil {
        return nil, err
    }
    
    gcm, err := cipher.NewGCM(cipher)
    if err != nil {
        return nil, err
    }
    
    ciphertext := gcm.Seal(nonce, nonce, data, nil)
    return ciphertext, nil
}
```

**迁移策略**:
1. 直接复制 `core/crypto/` 到新项目
2. 保持 API 不变
3. 添加单元测试

#### 3.2 迁移快照模块

**CC-Box 核心实现**:

```go
// core/snapshot/scanner.go
type FileInfo struct {
    Path     string
    Hash     string
    Size     int64
    ModTime  time.Time
    IsDir    bool
}

func Scan(root string, exclude []string) ([]FileInfo, error) {
    var files []FileInfo
    
    err := filepath.Walk(root, func(path string, info os.FileInfo, err error) error {
        if err != nil {
            return err
        }
        
        // 检查是否在排除列表中
        relPath, _ := filepath.Rel(root, path)
        if shouldExclude(relPath, exclude) {
            if info.IsDir() {
                return filepath.SkipDir
            }
            return nil
        }
        
        // 计算文件哈希
        hash, err := hashFile(path)
        if err != nil {
            return err
        }
        
        files = append(files, FileInfo{
            Path:    relPath,
            Hash:    hash,
            Size:    info.Size(),
            ModTime: info.ModTime(),
            IsDir:   info.IsDir(),
        })
        
        return nil
    })
    
    return files, err
}
```

**迁移策略**:
1. 直接复制 `core/snapshot/` 到新项目
2. 根据需要扩展扫描选项
3. 添加 Windows 特定处理

#### 3.3 迁移 WebDAV 模块

**CC-Box 核心实现**:

```go
// core/webdav/client.go
type Client struct {
    baseURL    string
    username   string
    password   string
    httpClient *http.Client
    timeout   time.Duration
}

func (c *Client) Upload(path string, data []byte) error {
    url := c.baseURL + "/" + path
    
    req, err := http.NewRequest("PUT", url, bytes.NewReader(data))
    if err != nil {
        return err
    }
    
    req.SetBasicAuth(c.username, c.password)
    req.Header.Set("Content-Type", "application/octet-stream")
    
    resp, err := c.httpClient.Do(req)
    if err != nil {
        return err
    }
    defer resp.Body.Close()
    
    if resp.StatusCode != http.StatusCreated && resp.StatusCode != http.StatusNoContent {
        return fmt.Errorf("upload failed: %s", resp.Status)
    }
    
    return nil
}

func (c *Client) Download(path string) ([]byte, error) {
    url := c.baseURL + "/" + path
    
    req, err := http.NewRequest("GET", url, nil)
    if err != nil {
        return nil, err
    }
    
    req.SetBasicAuth(c.username, c.password)
    
    resp, err := c.httpClient.Do(req)
    if err != nil {
        return nil, err
    }
    defer resp.Body.Close()
    
    if resp.StatusCode != http.StatusOK {
        return nil, fmt.Errorf("download failed: %s", resp.Status)
    }
    
    return io.ReadAll(resp.Body)
}
```

**迁移策略**:
1. 直接复制 `core/webdav/` 到新项目
2. 添加代理支持
3. 优化错误处理

---

### 第四阶段：UI 集成 (5-7 天)

#### 4.1 界面布局设计

**Dashboard 页面**:
```
┌─────────────────────────────────────────────────────────────┐
│  CC-Switch                                    [设置] [?]   │
├─────────┬───────────────────────────────────────────────────┤
│         │                                                   │
│  📊 仪表盘  │  同步状态: ✓ 已同步                             │
│  📁 文件   │  上次同步: 2024-01-01 12:00                    │
│  💾 二进制  │  冲突: 0                                        │
│  📚 项目   │  未同步变更: 0                                   │
│  📜 历史   │                                                   │
│  ⚙️ 设置   │  [同步全部]  [推送更改]  [拉取更改]              │
│         │                                                   │
├─────────┴───────────────────────────────────────────────────┤
│  最近活动                                                 │
│  - 12:00 已同步配置文件                                      │
│  - 11:30 上传 claude.exe v1.2.3                            │
│  - 11:00 检测到 settings.json 冲突                          │
└─────────────────────────────────────────────────────────────┘
```

**Files 页面**:
```
┌─────────────────────────────────────────────────────────────┐
│  📁 文件管理                                    [同步全部]   │
├─────────────────────────────────────────────────────────────┤
│  状态筛选: [全部 ▼]  搜索: [________________]                │
├─────────────────────────────────────────────────────────────┤
│  ☑ 文件/目录                    状态        大小    修改时间 │
│  ├─ 📄 settings.json            已同步      2.1 KB  11:30  │
│  ├─ 📄 CLAUDE.md               已修改 ⚠    4.5 KB  11:25  │
│  ├─ 📁 skills/                 已同步               10:00  │
│  │  ├─ 📄 math-skill.md        已同步      1.2 KB  10:00  │
│  │  └─ 📄 ocr-skill.md         已新增 🆕    0.8 KB  10:05  │
│  └─ 📁 agents/                 已同步               09:00  │
├─────────────────────────────────────────────────────────────┤
│  Diff: settings.json                                       │
│  ┌────────────────────┬────────────────────┐               │
│  │ - api_key = "xxx"  │ + api_key = "yyy"  │               │
│  │   model = "deepseek│   model = "claude" │               │
│  └────────────────────┴────────────────────┘               │
│  [使用本地版本]  [使用远程版本]  [手动合并]                  │
└─────────────────────────────────────────────────────────────┘
```

#### 4.2 集成 Wails

**如果 CC-Switch 使用 Wails**:

```go
// main.go
package main

import (
    "github.com/wailsapp/wails/v2/pkg/options"
    "github.com/wailsapp/wails/v2/pkg/options/assetserver"
    "github.com/wailsapp/wails/v2/pkg/options/windows"
)

func main() {
    app := NewApp()
    
    err := wails.Run(&options.Options{
        Title:  "CC-Switch",
        Width:  1200,
        Height: 800,
        AssetServer: &assetserver.Options{
            Assets: resources,
        },
        Windows: &windows.Options{
            WebviewIsTransparent: false,
            WindowIsTranslucent:   false,
        },
        OnStartup: app.startup,
        OnDomReady: app.domReady,
        OnBeforeClose: app.beforeClose,
        Bindings: []interface{}{
            app,
        },
    })
    
    if err != nil {
        println("Error:", err.Error())
    }
}

// 绑定方法示例
func (a *App) SyncAll() error {
    return a.sync.Sync()
}

func (a *App) Push() error {
    return a.sync.Push()
}

func (a *App) Pull() error {
    return a.sync.Pull()
}

func (a *App) GetStatus() (*SyncStatus, error) {
    return a.sync.Status()
}

func (a *App) ListVersions() ([]ClaudeVersion, error) {
    return a.binary.List()
}
```

---

### 第五阶段：测试和优化 (3-5 天)

#### 5.1 功能测试

```bash
# 测试加密解密
go test ./core/crypto/... -v

# 测试快照创建
go test ./core/snapshot/... -v

# 测试 WebDAV 操作
go test ./core/webdav/... -v

# 测试同步流程
go test ./core/sync/... -v
```

#### 5.2 集成测试

```go
// integration_test.go
func TestFullSync(t *testing.T) {
    // 1. 初始化
    sync := setupTestSync()
    
    // 2. 推送
    err := sync.Push()
    assert.NoError(t, err)
    
    // 3. 拉取
    err = sync.Pull()
    assert.NoError(t, err)
    
    // 4. 验证状态
    status, err := sync.Status()
    assert.NoError(t, err)
    assert.Equal(t, 0, status.UnsyncedChanges)
}
```

#### 5.3 UI 测试

- 手动测试所有页面
- 测试响应式布局
- 测试错误提示
- 测试加载状态

---

## 🎨 核心功能迁移

### 功能映射表

| CC-Box 功能 | 迁移优先级 | 迁移难度 | 备注 |
|------------|----------|---------|------|
| 加密/解密 | ⭐⭐⭐ 核心 | 🟢 简单 | 直接复制 core/crypto/ |
| 快照管理 | ⭐⭐⭐ 核心 | 🟡 中等 | 需要适配路径处理 |
| WebDAV 同步 | ⭐⭐⭐ 核心 | 🟡 中等 | 保持原样 |
| 对象存储 | ⭐⭐⭐ 核心 | 🟢 简单 | 直接复制 core/object/ |
| CLI 命令 | ⭐⭐ 次要 | 🟢 简单 | 可选 |
| GUI 界面 | ⭐⭐ 次要 | 🔴 复杂 | 需要重写 |
| 二进制管理 | ⭐ 可选 | 🟡 中等 | 根据需求 |
| 项目同步 | ⭐ 可选 | 🟡 中等 | 根据需求 |

---

## ⚠️ 注意事项

### 1. 安全性
- **不要修改加密算法**: Argon2id + AES-256-GCM 是安全的
- **密钥管理**: 确保加密密钥安全存储
- **密码强度**: 提示用户使用强密码

### 2. 兼容性
- **Windows 路径**: 需要特殊处理 `~\AppData\Roaming\` 等路径
- **权限问题**: 确保有读写权限
- **符号链接**: 需要处理符号链接

### 3. 性能
- **大文件**: 需要流式处理
- **并发**: WebDAV 操作需要限流
- **缓存**: 适当缓存以提高性能

### 4. 错误处理
- **网络错误**: 重试机制
- **冲突检测**: 及时通知用户
- **数据损坏**: 备份机制

---

## 📚 参考文档

### CC-Box 关键文件

| 文件 | 功能 | 优先级 |
|------|------|--------|
| [core/crypto/keygen.go](file:///D:/projects/add/cc-box/core/crypto/keygen.go) | 密钥生成 | 🔴 必须 |
| [core/crypto/secure_file.go](file:///D:/projects/add/cc-box/core/crypto/secure_file.go) | 文件加密 | 🔴 必须 |
| [core/snapshot/scanner.go](file:///D:/projects/add/cc-box/core/snapshot/scanner.go) | 文件扫描 | 🔴 必须 |
| [core/snapshot/snapshot.go](file:///D:/projects/add/cc-box/core/snapshot/snapshot.go) | 快照管理 | 🔴 必须 |
| [core/object/store.go](file:///D:/projects/add/cc-box/core/object/store.go) | 对象存储 | 🔴 必须 |
| [core/webdav/client.go](file:///D:/projects/add/cc-box/core/webdav/client.go) | WebDAV 客户端 | 🔴 必须 |
| [core/sync/merger.go](file:///D:/projects/add/cc-box/core/sync/merger.go) | 合并逻辑 | 🟡 推荐 |
| [core/binary/install.go](file:///D:/projects/add/cc-box/core/binary/install.go) | 二进制安装 | 🟢 可选 |
| [gui/frontend/src/pages/Dashboard.svelte](file:///D:/projects/add/cc-box/gui/frontend/src/pages/Dashboard.svelte) | 仪表盘 UI | 🟡 推荐 |

---

## 🚀 下一步行动

### 立即执行 (今天)
1. ✅ 克隆 CC-Box 仓库 (已完成)
2. 📋 阅读 CC-Box 核心模块代码
3. 📋 分析 CC-Switch 现有功能

### 本周计划
1. ✅ 设计统一 API 接口
2. ✅ 开始迁移核心模块
3. ✅ 编写集成测试

### 下周计划
1. ✅ 完成核心功能迁移
2. ✅ 开始 UI 集成
3. ✅ 进行全面测试

---

如果您准备好开始实施，请告诉我，我会为您提供详细的代码实现和具体的迁移步骤！
