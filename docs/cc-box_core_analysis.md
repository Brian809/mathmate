# CC-Box 核心模块详细分析报告

## 📋 目录
- [加密模块 (core/crypto)](#加密模块-corecrypto)
- [快照模块 (core/snapshot)](#快照模块-coresnapshot)
- [对象存储模块 (core/object)](#对象存储模块-coreobject)
- [WebDAV 模块 (core/webdav)](#webdav-模块-corewebdav)
- [同步模块 (core/sync)](#同步模块-coresync)
- [二进制管理模块 (core/binary)](#二进制管理模块-corebinary)
- [架构设计亮点总结](#架构设计亮点总结)

---

## 🔐 加密模块 (core/crypto)

### 核心文件
- `keygen.go` - 密钥生成
- `secure_file.go` - 安全文件操作

### 加密算法

#### Argon2id 密钥派生

```go
// 参数配置
argonTime    = 3      // 迭代次数：安全优先
argonMemory  = 64MB   // 内存需求：抵抗 GPU/ASIC
argonThreads = 4      // 并行线程数
argonKeyLen  = 32B    // 256-bit 密钥
saltSize     = 16B    // 128-bit Salt
```

**为什么选择 Argon2id？**

| 特性 | Argon2id | bcrypt | PBKDF2 |
|------|----------|--------|--------|
| 内存硬度 | ✅ 64MB | ❌ 4MB | ❌ 无 |
| GPU 抗性 | ✅ 优秀 | ⚠️ 中等 | ❌ 差 |
| 侧信道安全 | ✅ 优秀 | ⚠️ 中等 | ✅ 优秀 |
| 标准化 | ✅ RFC | ⚠️ 无 | ✅ RFC |

#### AES-256-GCM 加密

```go
// 加密格式
[1B版本号] [12B随机nonce] [N字节密文+16B认证标签]
```

**安全特性**：
- ✅ **机密性**：AES-256 加密
- ✅ **完整性**：GCM 模式提供认证标签
- ✅ **防重放**：随机 nonce 确保每次加密结果不同

### 核心函数

```go
// 1. 生成随机盐值
func GenerateSalt() ([]byte, error)

// 2. 密钥派生
func DeriveKey(password string, salt []byte) []byte

// 3. 加密
func Encrypt(plaintext []byte, key []byte) ([]byte, error)

// 4. 解密
func Decrypt(ciphertext []byte, key []byte) ([]byte, error)

// 5. 密钥指纹
func KeyFingerprint(key []byte) string
```

### 安全设计亮点

1. **盐值共享机制**
   - 所有设备使用相同的 `salt.bin`
   - 确保同一密码派生相同密钥
   - salt 存储在 WebDAV

2. **密钥从不传输**
   - 密码本地派生密钥
   - 只有加密数据上传到 WebDAV
   - 即使 WebDAV 被攻破，攻击者也无法解密

3. **文件权限保护**
   ```go
   // 密钥文件权限 0600 (仅当前用户可读)
   os.WriteFile(keyPath, key, 0600)
   ```

---

## 📦 快照模块 (core/snapshot)

### 核心文件
- `scanner.go` - 文件扫描器
- `snapshot.go` - 快照管理

### 快照数据结构

```go
type Snapshot struct {
    ID        string                      // 快照 ID (SHA256前8字符)
    Parent    string                      // 父快照 ID (链式存储)
    Timestamp time.Time                   // 创建时间
    Device    string                      // 设备名称
    Message   string                      // 提交消息
    Files     map[string]FileEntry        // 文件映射
    Binary    map[string]map[string]string // Claude 二进制信息
}

type FileEntry struct {
    Hash     string    // 内容哈希 (SHA256)
    Size     int64     // 文件大小
    Modified time.Time // 修改时间
}
```

### 扫描流程

```
Sc anner.Scan()
    ↓
遍历 ~/.claude/ 目录
    ↓
检查排除规则
    ↓
跳过符号链接 (不支持)
    ↓
检测路径大小写冲突 (Windows)
    ↓
读取文件并计算哈希
    ↓
生成文件条目映射
    ↓
返回快照
```

### 排除规则设计

```go
// 支持3种排除模式
excludePatterns = [
    "cache/",      // 目录后缀匹配
    "*.lock",      // 通配符匹配
    ".git/",       // 精确路径匹配
]
```

**匹配逻辑**：
```go
// 目录后缀: 匹配任意路径段
"cache/" → 匹配 "dir/cache/" 或 "cache/file"

// 通配符: 匹配文件名
"*.lock" → 匹配 "a.lock", "b.lock"

// 精确路径: 完全匹配
".git/" → 匹配 ".git/" 或 ".git/file"
```

### 链式快照设计

```
快照链结构
┌─────────────────────────────────────────┐
│  快照 A (根)                             │
│  ID: snap_A, Parent: ""                 │
└─────────────────────────────────────────┘
           ↓ Parent
┌─────────────────────────────────────────┐
│  快照 B                                  │
│  ID: snap_B, Parent: snap_A              │
└─────────────────────────────────────────┘
           ↓ Parent
┌─────────────────────────────────────────┐
│  快照 C (HEAD)                           │
│  ID: snap_C, Parent: snap_B              │
└─────────────────────────────────────────┘
```

**优势**：
- ✅ 节省存储：只记录变更
- ✅ 历史追溯：沿链回溯所有版本
- ✅ 空间高效：无需完整副本

### Diff 算法

```go
// 计算两个快照的差异
func (old *Snapshot) Diff(new *Snapshot) []Change

// 变更类型
const (
    Added    = iota  // 新增
    Modified         // 修改
    Deleted          // 删除
)

// 示例
old: {A: v1, B: v1}
new: {A: v2, C: v1}

Changes:
- A: Modified (v1 → v2)
- B: Deleted (v1 → none)
- C: Added (none → v1)
```

---

## 🌐 对象存储模块 (core/object)

### 核心概念：内容寻址存储 (CAS)

```
内容 → 哈希 → 存储路径

data = "Hello World"
hash = SHA256(data) = "a591a6d40bf420404a011733cfb7b190d62c65bf0bcda32b57b277d9ad9f146e"
path = "objects/a5/a591a6d40bf420404a011733cfb7b190d62c65bf0bcda32b57b277d9ad9f146e.enc"
```

### 存储结构

```
WebDAV 根目录/
├── salt.bin              # 加密盐值
├── HEAD                  # 当前快照 ID
├── snapshots/
│   ├── {id1}.json.enc   # 加密的快照 JSON
│   ├── {id2}.json.enc
│   └── ...
└── objects/
    ├── {hash前2位}/
    │   └── {完整hash}.enc
    └── parts/
        └── {hash}/
            ├── manifest.json
            ├── part-000.enc
            └── part-001.enc
```

### 上传优化策略

```go
// 三级去重检查
Upload(data):
    1. 检查本地已知集合 (零网络)
       ↓ 已存在
       return hash
    
    2. 检查远程是否存在 (1次请求)
       ↓ 已存在
       return hash
    
    3. 上传新对象
       ↓
       加密
       ↓
       写入
```

### 分块上传机制

**触发条件**：
```go
// 文件 > 50MB 自动分块
threshold = 50 * 1024 * 1024  // 50MB
chunkSize = 10 * 1024 * 1024  // 每块 10MB
```

**分块流程**：
```
大文件 (100MB)
    ↓
分块1 (10MB) ──┐
分块2 (10MB) ──┼── manifest.json
分块3 (10MB) ──┤   - total_parts: 10
分块4 (10MB) ──┤   - part_hashes: [...]
分块5-10      ──┘   - total_size: 100MB
    ↓
每个分块独立加密
    ↓
上传到 objects/parts/{hash}/
```

### 本地缓存策略

```go
// 缓存目录结构
~/.cache/cc-box/objects/
└── {prefix}/
    └── {hash}.enc  // 加密缓存

// 缓存命中流程
Download(hash):
    1. 检查本地缓存
       ↓ 命中
       解密 + 校验哈希
       ↓ 成功
       return data
       
    2. 远程下载
       ↓
       解密
       ↓
       写入缓存
       ↓
       return data
```

---

## 🔗 WebDAV 模块 (core/webdav)

### 客户端设计

```go
type Client struct {
    baseURL     string      // WebDAV 服务器地址
    baseURLPath string      // URL 路径部分
    username    string      // 认证用户名
    password    string      // 认证密码
    http        *http.Client
}
```

### 核心操作

| 方法 | HTTP 动词 | 用途 |
|------|-----------|------|
| `GET` | GET | 下载文件 |
| `PUT` | PUT | 上传文件 |
| `HEAD` | HEAD | 获取文件元信息 |
| `DELETE` | DELETE | 删除文件 |
| `MKCOL` | MKCOL | 创建目录 |
| `PROPFIND` | PROPFIND | 列出目录 |

### ETag 条件请求

**防止并发冲突**：
```go
// 1. 读取当前 ETag
info, _ := client.HEAD("HEAD")
oldETag := info.ETag

// 2. 更新时携带 ETag
newETag, err := client.PUT("HEAD", newData, oldETag)

// 3. 如果 ETag 不匹配 (其他设备已更新)
if err == ErrConflict {
    // 需要先拉取最新版本
    return ConflictError
}
```

**原子创建**：
```go
// 仅当文件不存在时创建
// 用于防止覆盖
client.PUTIfAbsent("new_file", data)
```

### 目录自动创建

```go
// MKCOL 递归创建父目录
client.MKCOL("dir1/dir2/dir3")
// 自动创建: dir1, dir1/dir2, dir1/dir2/dir3
```

### 错误处理

```go
// 常见错误
ErrNotFound      // 404 文件不存在
ErrConflict       // 412 Precondition Failed
```

---

## ⚔️ 同步模块 (core/sync)

### 三路合并算法

```go
// 三路合并
Merge(local, remote, ancestor) → result

本地   远程   祖先
  │      │      │
  │      │      └─ 共同基础版本
  │      │
  │      └─ 远程修改
  │
  └─ 本地修改
```

**合并场景**：

#### 场景 1：无冲突
```
祖先: settings.json = "key=123"
本地: settings.json = "key=456"
远程: settings.json = "key=789"
结果: settings.json = "key=456" (本地胜出) 或 "key=789" (远程胜出)
```

#### 场景 2：同一文件修改
```
祖先: settings.json = "key=123"
本地: settings.json = "key=456"
远程: settings.json = "key=789"
结果: 冲突！需要用户选择或手动合并
```

#### 场景 3：删除 vs 修改
```
祖先: settings.json = "key=123"
本地: 删除 settings.json
远程: settings.json = "key=456"
结果: 冲突！删除方 vs 修改方
```

### 冲突检测

```go
type Conflict struct {
    Path      string
    LocalSHA  string
    RemoteSHA string
    AncestorSHA string
    Type     ConflictType
}

type ConflictType int
const (
    ModifiedModified ConflictType = iota  // 双方都修改
    DeletedModified                        // 一方删除，一方修改
    DeletedDeleted                         // 双方都删除
)
```

### 冲突解决策略

```go
// 解决策略
type Resolution int
const (
    UseLocal  Resolution = iota  // 使用本地版本
    UseRemote Resolution = iota  // 使用远程版本
    UseMerge  Resolution = iota // 使用合并版本
)

// 示例
ResolveConflict(conflictID, UseRemote)
// 远程版本胜出
```

---

## 💾 二进制管理模块 (core/binary)

### Claude 二进制管理

```go
type BinaryManager struct {
    platform string      // win/darwin/linux
    config   *PathConfig // 安装路径配置
}

type ClaudeVersion struct {
    Version   string  // 版本号
    Source    string  // "official" | "github" | "webdav"
    Installed bool    // 是否已安装
    Path      string  // 安装路径
    Size      int64   // 文件大小
    Hash      string  // SHA256 哈希
}
```

### 安装路径

| 平台 | 路径 |
|------|------|
| Windows | `~\.local\bin\claude.exe` |
| macOS | `~\.local\bin\claude` |
| Linux | `~\.local\bin\claude` |

### 三种安装源

```go
// 1. 官方安装器
InstallFromOfficial()
    ↓
执行官方安装脚本
    ↓
下载最新版本

// 2. GitHub Releases
InstallFromGitHub(version)
    ↓
从 GitHub 下载指定版本
    ↓
SHA256 校验
    ↓
安装到官方路径

// 3. WebDAV 备份
InstallFromWebDAV(version)
    ↓
下载本地备份版本
    ↓
验证哈希
    ↓
安装到官方路径
```

### 版本切换

```go
Switch(version string) error
    ↓
1. 备份当前版本
    ↓
2. 下载目标版本
    ↓
3. 安装到官方路径
    ↓
4. 运行 claude install 初始化
    ↓
5. 验证安装
    ↓
6. 失败则回滚
```

---

## 🎨 架构设计亮点总结

### 1. **模块化设计**

```
cc-box/
├── core/          # 核心逻辑库
├── cli/           # 命令行工具
└── gui/           # 桌面应用

core/
├── crypto/        # 加密模块 (独立)
├── snapshot/      # 快照模块 (独立)
├── object/        # 对象存储 (独立)
├── webdav/        # WebDAV 客户端 (独立)
├── binary/        # 二进制管理 (独立)
└── sync/          # 同步逻辑 (独立)
```

**优势**：
- ✅ 模块可独立测试
- ✅ CLI 和 GUI 共享核心逻辑
- ✅ 便于单元测试和集成测试

### 2. **安全优先**

- ✅ 端到端加密 (密钥从不传输)
- ✅ 内存硬密钥派生 (Argon2id)
- ✅ 文件权限保护 (0600)
- ✅ 完整性校验 (GCM 认证标签)
- ✅ 强随机数 (crypto/rand)

### 3. **性能优化**

- ✅ 三级去重检查
- ✅ 本地缓存
- ✅ 分块上传 (大文件)
- ✅ 增量同步 (Diff)

### 4. **可靠性设计**

- ✅ ETag 防止并发冲突
- ✅ 原子操作 (Compare-And-Swap)
- ✅ 冲突检测和解决
- ✅ 版本回滚支持

### 5. **跨平台兼容**

- ✅ Windows 路径处理
- ✅ macOS 权限管理
- ✅ Linux 文件系统
- ✅ 统一抽象接口

---

## 📊 关键设计决策总结

| 决策 | 选择 | 理由 |
|------|------|------|
| 加密算法 | Argon2id + AES-256-GCM | 安全性最高 |
| 存储格式 | 内容寻址 | 高效去重 |
| 同步协议 | WebDAV | 通用性强 |
| 冲突策略 | 三路合并 + 手动解决 | 数据安全优先 |
| 版本管理 | 链式快照 | 空间高效 |
| 缓存策略 | 本地加密缓存 | 性能优化 |

---

## 🎯 对 CC-Switch 集成的建议

### 1. **直接复用 core 模块**

最简单的方式是直接将 CC-Box 的 `core/` 目录复制到新项目中：

```bash
cp -r cc-box/core ./cc-switch/
```

### 2. **保持 API 一致**

复用时保持函数签名不变：

```go
// 直接使用 CC-Box 的 API
import "github.com/cc-box/core/crypto"

key := crypto.DeriveKey(password, salt)
encrypted, _ := crypto.Encrypt(data, key)
```

### 3. **渐进式迁移**

```
Phase 1: 复制 core/ 到新项目
Phase 2: 替换现有加密逻辑
Phase 3: 替换现有存储逻辑
Phase 4: 替换现有同步逻辑
Phase 5: 优化 UI 集成
```

### 4. **保持向后兼容**

```go
// CC-Switch 已有数据迁移
type LegacyConfig struct {
    APIKey    string
    WebDAVURL string
}

func MigrateLegacyConfig(cfg *LegacyConfig) (*ccbox.Config, error) {
    // 转换配置格式
    return &ccbox.Config{
        Encryption: ccbox.EncryptionConfig{
            Enabled: true,
            Salt:    generateSalt(),
        },
        WebDAV: ccbox.WebDAVConfig{
            URL:      cfg.WebDAVURL,
            Username: cfg.APIKey,
        },
    }, nil
}
```

---

## 📚 参考文档

### 核心模块代码
- [crypto/keygen.go](file:///D:/projects/add/cc-box/core/crypto/keygen.go)
- [crypto/secure_file.go](file:///D:/projects/add/cc-box/core/crypto/secure_file.go)
- [snapshot/scanner.go](file:///D:/projects/add/cc-box/core/snapshot/scanner.go)
- [snapshot/snapshot.go](file:///D:/projects/add/cc-box/core/snapshot/snapshot.go)
- [object/store.go](file:///D:/projects/add/cc-box/core/object/store.go)
- [webdav/client.go](file:///D:/projects/add/cc-box/core/webdav/client.go)
- [sync/merger.go](file:///D:/projects/add/cc-box/core/sync/merger.go)
- [binary/install.go](file:///D:/projects/add/cc-box/core/binary/install.go)

### 项目文档
- [CC-Box README](file:///D:/projects/add/cc-box/README.md)
- [CC-Box 集成方案](file:///D:/projects/MathMate/docs/cc-box_integration_plan.md)
