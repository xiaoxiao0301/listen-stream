# Listen Stream — 项目 Plan 文档

> 更新日期：2026-02-20

---

## 1. 项目概述

Listen Stream 是一款多平台音乐流媒体客户端，支持以下终端：

| 平台 | 说明 |
|------|------|
| Desktop | Windows / macOS / Linux 跨平台桌面版 |
| Android | 手机 + 平板 |
| iOS | iPhone + iPad |
| Android TV | 大屏电视端 |
| Admin Web | 后台管理控制台（Web 端，管理员专用） |

**核心约束：**
- 客户端**不直接调用第三方接口**，所有数据经由自有 **API 代理层** 中转
- 服务器带宽与硬盘有限，客户端须实现**本地缓存 + 按需加载**，禁止预加载全量第三方数据
- 用户通过**手机号 + 短信验证码**登录，支持多端 JWT 会话
- 多端数据（收藏、历史、歌单）须**跨设备实时同步**
- 系统具备**完整权限分层**，Admin 端负责平台配置与用户管理

---

## 2. 整体架构

```
┌──────────────────────────────────────────────────────────────────┐
│                           客户端层                                │
│  Desktop(Flutter)  Mobile(Flutter)  Android TV(Flutter)          │
└────────────────────────────┬─────────────────────────────────────┘
                             │ HTTPS + JWT
┌────────────────────────────▼─────────────────────────────────────┐
│                        后端服务层（自研）                          │
│ ┌─────────────┐  ┌──────────────┐  ┌───────────────────────────┐ │
│ │  Auth 服务   │  │  API 代理层  │  │      同步 / 用户数据服务   │ │
│ │ 手机号+验证码 │  │ 第三方接口封装│  │  收藏/历史/歌单 跨端同步  │ │
│ │ JWT 签发/刷新│  │ 密钥/Cookie  │  │  WebSocket 实时推送       │ │
│ └─────────────┘  └──────────────┘  └───────────────────────────┘ │
│ ┌──────────────────────────────────────────────────────────────┐  │
│ │                      Admin 管理服务                          │  │
│ │  系统初始化 / 第三方 API 配置 / JWT 配置 / 用户权限管理       │  │
│ └──────────────────────────────────────────────────────────────┘  │
└────────────────────────────┬─────────────────────────────────────┘
                             │ 服务器内网
       ┌─────────────────────┼──────────────────┐
       ▼                     ▼                  ▼
  短信网关(SMS)        第三方音乐平台接口        数据库/缓存
  (阿里云/腾讯云)    (由代理层统一调用)      (PostgreSQL + Redis)

                             │ HTTPS（Admin Web）
┌────────────────────────────▼─────────────────────────────────────┐
│                      Admin 控制台（Web）                          │
│  Next.js — 仅管理员可访问，部署在独立子域名，建议限制 IP 访问     │
└──────────────────────────────────────────────────────────────────┘
```

---

## 3. 权限分层（RBAC）

系统设计三级权限角色：

| 角色 | 标识 | 权限范围 |
|------|------|----------|
| 超级管理员 | `super_admin` | 全部权限：系统初始化、API 密钥配置、JWT 配置、用户管理、内容管理 |
| 普通管理员 | `admin` | 用户管理（不含权限变更）、内容审核、查看系统状态 |
| 普通用户 | `user` | 音乐收听、收藏、历史记录、个人数据同步 |

### 3.1 权限控制实现

- 后端所有接口通过 **JWT Claims** 携带角色信息，中间件统一校验
- Admin Web 按角色显示/隐藏菜单项，同时后端二次鉴权（不依赖前端隐藏）
- 客户端仅有 `user` 权限，Admin 功能不对客户端开放
- 角色变更需要 `super_admin` 操作，操作必须记录日志

---

## 4. 认证体系

### 4.1 用户登录（手机号 + 验证码）

```
1. 客户端提交手机号 → POST /auth/sms/send
2. SMS 网关发送 6 位验证码（有效期 5 分钟，同手机号 60 秒内不可重发）
3. 客户端提交手机号 + 验证码 → POST /auth/sms/verify
4. 服务端验证通过 → 签发 Access Token（1h）+ Refresh Token（30d）
5. 客户端本地加密存储 Refresh Token，请求时携带 Access Token
6. Access Token 过期 → 自动用 Refresh Token 换取新 Access Token
7. Refresh Token 过期 → 引导重新登录
```

### 4.2 JWT 配置项（Admin 可配置）

| 配置项 | 说明 | 示例 |
|--------|------|------|
| `JWT_SECRET` | 签名密钥（HS256 或 RS256） | 256-bit 随机串 |
| `ACCESS_TOKEN_TTL` | Access Token 有效期 | `3600`（秒） |
| `REFRESH_TOKEN_TTL` | Refresh Token 有效期 | `2592000`（秒） |
| `JWT_ISSUER` | 签发方标识 | `listen-stream` |
| `MAX_DEVICES` | 单用户最大同时在线设备数 | `5` |

### 4.3 多端会话管理

- 每次登录生成唯一 `device_id`，服务端维护设备会话表
- 超出 `MAX_DEVICES` 时，踢出最早登录的设备
- 用户可在个人中心查看并主动注销指定设备

### 4.4 Admin 登录

Admin Web 使用**用户名 + 密码**登录（不对外暴露手机号登录入口）：
- 首次部署通过**初始化向导**设置超级管理员账号（详见第 6 节）
- 密码使用 Argon2id 哈希存储
- 支持 TOTP 二次验证（可选，推荐开启）

---

## 5. API 代理层详细设计

### 5.1 代理层职责

| 职责 | 说明 |
|------|------|
| 凭证管理 | 统一持有第三方平台 AppKey、Secret、Cookie，客户端无感知 |
| 请求转发 | 将客户端请求转换为第三方接口格式 |
| 响应标准化 | 将第三方返回统一转换为平台响应格式 |
| 服务端缓存 | 对热点数据做 Redis 缓存，减少带宽和对外请求 |
| 限流 | 按用户 / IP 限制请求频率，防止滥用 |
| 日志 | 记录所有对外请求，便于排查密钥失效、接口变更 |

### 5.2 第三方 API 配置（Admin 可管理）

Admin 端提供配置界面，所有敏感配置**加密存储于数据库**，不写入代码或环境变量：

| 配置字段 | 说明 |
|----------|------|
| `API_BASE_URL` | 第三方接口 Base URL |
| `APP_KEY` | 应用 Key / Client ID |
| `APP_SECRET` | 应用 Secret / Client Secret |
| `COOKIE` | 登录态 Cookie（支持在线刷新） |
| `COOKIE_REFRESH_CRON` | Cookie 自动刷新 Cron 表达式 |
| `REQUEST_TIMEOUT` | 请求超时时间（ms） |
| `RETRY_TIMES` | 失败重试次数 |
| 状态 | 启用 / 禁用开关，禁用后代理层返回降级数据 |

### 5.3 服务端缓存（节省带宽）

| 数据类型 | 缓存位置 | TTL |
|----------|----------|-----|
| Banner / 推荐歌单 | Redis | 30min |
| 歌单分类 | Redis | 6h |
| 排行榜列表 | Redis | 1h |
| 歌手基础信息 | Redis | 12h |
| 搜索热词 | Redis | 15min |
| 歌曲播放 URL | **不缓存** | — |
| 歌词 | Redis | 7d |

---

## 6. Admin 控制台

### 6.1 系统初始化（首次部署向导）

首次访问 Admin Web 时，若数据库中无任何管理员账号，显示初始化向导：

```
步骤 1 — 数据库连接检测（自动）
步骤 2 — 创建超级管理员
         · 用户名（不可与系统保留名重复）
         · 密码（强度校验：≥12位，含大小写+数字+特殊字符）
         · 确认密码
步骤 3 — 基础配置
         · 站点名称
         · SMS 网关类型（阿里云 / 腾讯云）及 Access Key
         · 短信模板 ID
步骤 4 — 完成初始化 → 跳转登录页
```

初始化完成后，该向导**永久关闭**，再次访问直接跳转登录。

### 6.2 Admin 功能模块

#### 6.2.1 仪表盘

- 在线用户数、今日活跃设备数
- 服务器请求量折线图（按小时）
- 缓存命中率、第三方 API 调用次数
- 系统告警（Cookie 即将过期、API 配额不足等）

#### 6.2.2 第三方 API 配置

- 查看 / 编辑 API_BASE_URL、AppKey、Secret
- Cookie 管理：状态展示（有效/过期）、手动刷新、配置自动刷新 Cron
- 连通性测试：一键发送测试请求，显示响应状态和耗时
- 历史变更记录（变更时间、操作人）

#### 6.2.3 JWT 配置

- 查看 / 修改 JWT Secret（修改后所有用户下线，需二次确认）
- 配置 Access Token / Refresh Token 有效期
- 配置单用户最大设备数
- 强制下线全部用户（紧急操作，需 `super_admin`）

#### 6.2.4 用户管理

| 操作 | 所需角色 |
|------|----------|
| 查看用户列表 | admin / super_admin |
| 搜索用户（手机号） | admin / super_admin |
| 禁用 / 启用用户 | admin / super_admin |
| 强制注销指定设备 | admin / super_admin |
| 修改用户角色 | super_admin 专有 |
| 删除用户 | super_admin 专有 |

#### 6.2.5 SMS 配置

- 选择 SMS 服务商（阿里云 / 腾讯云）
- 填写 AccessKey、SecretKey、短信签名、模板 ID
- 发送测试短信验证配置

#### 6.2.6 系统日志

- API 代理请求日志（按接口 / 状态码 / 时间筛选）
- 管理员操作日志（操作人、类型、时间、变更前后值）
- 用户登录日志

### 6.3 Admin Web 技术选型

| 维度 | 选型 |
|------|------|
| 框架 | Next.js 15（App Router） |
| UI 组件库 | shadcn/ui + Tailwind CSS |
| 状态管理 | Zustand |
| HTTP 客户端 | Axios + React Query |
| 图表 | Recharts |
| 认证 | NextAuth.js（自定义 credentials provider） |
| 部署 | 独立子域名，nginx 反代，建议限制 IP 访问 |

---

## 7. 客户端缓存策略

### 7.1 缓存分级

| 级别 | 存储位置 | 适用数据 | 失效策略 |
|------|----------|----------|----------|
| L1 内存缓存 | Riverpod Provider keepAlive | 当前会话内高频列表 | App 重启失效 |
| L2 磁盘缓存 | Isar | 歌单详情、歌手信息、歌词、封面元数据 | TTL + 版本号比对 |
| L3 图片缓存 | `cached_network_image` | 封面图、歌手头像 | LRU，最大 200MB |

### 7.2 各模块缓存 TTL

| 模块 | 客户端缓存时长 | 备注 |
|------|----------------|------|
| 首页 Banner | 30min | |
| 推荐歌单列表 | 1h | |
| 歌单详情 + 歌曲 | 6h | dissid 作为缓存 Key |
| 歌手详情 + 歌曲 | 12h | singer_mid 作为缓存 Key |
| 排行榜详情 | 1h | id + period 作为 Key |
| 搜索结果 | 5min | 关键词 + 类型 + 页码 |
| 歌词 | 永久（版本绑定） | song_mid 作为 Key |
| 播放 URL | **不缓存** | 每次播放实时获取 |
| MV 视频 URL | **不缓存** | 同上 |

### 7.3 按需加载原则

- **分页懒加载**：所有列表均分页（默认 20 条），滚动到底才触发下一页
- **Tab 懒初始化**：歌手详情专辑/MV Tab 仅在用户点击时才请求
- **视口延迟加载**：首页各 Section 进入视口才触发请求
- **图片懒加载**：使用 `cached_network_image` 懒加载模式
- **禁止全量预取**：启动仅请求首页必要数据（Banner + 推荐歌单）

### 7.4 缓存一致性

- 后台静默发起 ETag 条件请求，服务端返回 `304` 时不消耗带宽
- 用户下拉刷新 → 强制绕过缓存
- 用户数据以服务端版本为准，本地仅作离线展示

---

## 8. 多端数据同步

### 8.1 同步数据范围

| 数据 | 同步方式 | 说明 |
|------|----------|------|
| 收藏歌曲 | 云端存储 + WebSocket 实时推送 | 以服务端为准 |
| 收藏专辑 / 歌手 | 云端存储 + WebSocket 实时推送 | |
| 播放历史 | 定时上报（每 30s 或播放完成时） | 最近 500 条 |
| 播放进度 | 定时上报（每 10s）+ 退出时上报 | 跨端续播 |
| 自建歌单 | 云端存储 + WebSocket 实时推送 | |
| 用户偏好设置 | 登录时同步一次 | 音质、主题色等 |

### 8.2 同步架构

```
客户端 A 发起收藏操作
    │
    ▼
POST /user/favorites  → 服务端更新数据库
    │
    ▼
服务端通过 WebSocket 推送给同一用户其他在线设备
    │
    ▼
客户端 B / C 收到推送 → 更新本地缓存 → UI 自动刷新
```

- App 切入后台 > 30s 断开 WebSocket，前台重连并拉取离线变更（`GET /user/sync?since=`）
- 冲突解决：**服务端时间戳优先**（Last-Write-Wins）

### 8.3 离线模式

- 已缓存的歌曲信息、歌词、封面无网络时可正常查看
- 无网络时操作存入本地队列，恢复网络后自动上报

---

## 9. 技术选型

### 9.1 客户端框架（Flutter）

| 维度 | 说明 |
|------|------|
| 框架 | Flutter 3.x (Dart) |
| 桌面端 | Flutter Desktop（Windows / macOS / Linux，官方 Stable） |
| 移动端 | Flutter Android & iOS（官方 Stable） |
| Android TV | Flutter Android，manifest 声明 `android.hardware.type.television`，D-pad 导航 |
| 代码复用率 | 业务逻辑、UI 组件、网络层 ~85% 共享 |

### 9.2 状态管理

**Riverpod 2.x**：`AsyncNotifierProvider` + `keepAlive` 控制 Provider 生命周期，配合缓存策略避免重复请求。

### 9.3 网络层

| 库 | 用途 |
|----|------|
| `dio` | HTTP 请求，拦截器处理 JWT 自动刷新、重试、ETag |
| `retrofit` + `json_serializable` | 接口 DSL & 序列化 |
| `web_socket_channel` | WebSocket 实时同步 |
| `flutter_cache_manager` | 图片/资源 CDN 缓存 |

### 9.4 音频 / 视频播放

| 库 | 用途 |
|----|------|
| `just_audio` | 跨平台音频（HLS / MP3 / FLAC） |
| `audio_service` | 后台播放 + 系统媒体控件 |
| `video_player` | MV 视频播放 |
| `chewie` | 视频播放器 UI，全屏切换 |

### 9.5 本地持久化

| 库 | 用途 |
|----|------|
| `isar` | 结构化数据（歌单、收藏、历史、缓存元数据） |
| `shared_preferences` | 偏好设置 |
| `flutter_secure_storage` | JWT Refresh Token 加密存储 |

### 9.6 路由

`go_router`：声明式路由，支持 DeepLink

### 9.7 后端技术选型

**架构形态**：4 个独立 Go 微服务，通过 REST HTTP 互通，共用 PostgreSQL + Redis。

| 维度 | 选型 |
|------|------|
| 语言 | Go 1.23 |
| HTTP 框架 | Gin |
| DB 访问 | sqlc（类型安全代码生成）+ golang-migrate |
| 数据库驱动 | pgx/v5 |
| 缓存 | Redis 7（go-redis/v9） |
| JWT | golang-jwt/jwt/v5 |
| 配置加密 | AES-256-GCM（标准库 `crypto/aes`） |
| Admin 密码 | Argon2id（`golang.org/x/crypto/argon2`） |
| WebSocket | gorilla/websocket（sync-svc 内） |
| SMS | HTTP 直调阿里云 / 腾讯云 REST API |
| 日志 | uber-go/zap，结构化 JSON |
| 容器化 | Docker + docker-compose |

**4 个微服务端口分配**：

| 服务 | 端口 | 职责 |
|------|------|------|
| auth-svc | :8001 | SMS 验证码、JWT 签发/刷新、设备管理 |
| proxy-svc | :8002 | 第三方 API 代理转发、Redis 缓存、ETag |
| sync-svc | :8003 | 收藏/历史/歌单 CRUD、WebSocket 推送、离线同步 |
| admin-svc | :8004 | 系统配置、用户管理、Admin 认证、操作日志 |

---

## 10. 功能模块设计

### 10.1 首页（Home）

| 功能 | 接口 | 客户端缓存 |
|------|------|-----------|
| 轮播横幅 | `GET /recommend/banner` | 30min |
| 每日推荐歌单（登录） | `GET /recommend/daily` | 1h |
| 推荐歌单列表 | `GET /recommend/playlist` | 1h |
| 新歌推荐 | `GET /recommend/new/songs?type=` | 30min |
| 新专辑推荐 | `GET /recommend/new/albums?type=` | 30min |

加载策略：Banner + 推荐歌单立即加载，新歌/新专辑 Section 进入视口才请求。

### 10.2 歌单（Playlist）

| 功能 | 接口 | 客户端缓存 |
|------|------|-----------|
| 歌单分类 | `GET /playlist/category` | 6h |
| 分类歌单列表（分页） | `GET /playlist/information?number=&size=&sort=&id=` | 1h |
| 歌单详情 | `GET /playlist/detail?dissid=` | 6h |

### 10.3 歌手（Singer）

| 功能 | 接口 | 客户端缓存 |
|------|------|-----------|
| 筛选条件 | `GET /artist/category` | 6h |
| 歌手列表 | `GET /artist/list?area=&sex=&genre=&index=&page=&size=` | 2h |
| 歌手详情 + 歌曲 | `GET /artist/detail?id=&page=` | 12h |
| 歌手专辑列表 | `GET /artist/albums?id=&page=&size=` | 12h |
| 歌手 MV 列表 | `GET /artist/mvs?id=&page=&size=` | 12h |
| 歌手歌曲列表 | `GET /artist/songs?id=&page=&size=` | 12h |

加载策略：默认加载「歌曲」Tab，专辑/MV Tab 仅在用户点击时请求。

### 10.4 排行榜（Ranking）

| 功能 | 接口 | 客户端缓存 |
|------|------|-----------|
| 榜单分类及前三预览 | `GET /rankings/list` | 1h |
| 榜单详情（分页） | `GET /rankings/detail?id=&page=&size=&period=` | 1h |

### 10.5 电台（Radio）

| 功能 | 接口 | 客户端缓存 |
|------|------|-----------|
| 电台分类列表 | `GET /radio/category` | 6h |
| 电台歌曲列表 | `GET /radio/songlist?id=` | 不缓存（随机刷新） |

### 10.6 MV

| 功能 | 接口 | 客户端缓存 |
|------|------|-----------|
| MV 分类 | `GET /mv/category` | 6h |
| 分类 MV 列表 | `GET /mv/list?area=&version=&page=&size=` | 1h |
| MV 详情（播放地址） | `GET /mv/detail?id=` | 不缓存 |

### 10.7 专辑（Album）

| 功能 | 接口 | 客户端缓存 |
|------|------|-----------|
| 专辑详情 | `GET /album/detail?id=` | 12h |
| 专辑歌曲列表 | `GET /album/songs?id=` | 12h |

### 10.8 搜索（Search）

| 功能 | 接口 | 客户端缓存 |
|------|------|-----------|
| 热搜词 | `GET /search/hotkey` | 15min |
| 搜索歌曲 | `GET /search/?keyword=&type=0&page=&size=` | 5min |
| 搜索歌手 | `GET /search/?keyword=&type=9&page=&size=` | 5min |
| 搜索专辑 | `GET /search/?keyword=&type=8&page=&size=` | 5min |
| 搜索 MV | `GET /search/?keyword=&type=12&page=&size=` | 5min |

### 10.9 歌词（Lyric）

| 功能 | 接口 | 客户端缓存 |
|------|------|-----------|
| 歌词与翻译 | `GET /lyric?id=` | 永久（song_mid 绑定） |

### 10.10 播放器（Player）

全局单例：

| 功能 | 说明 |
|------|------|
| 播放 / 暂停 / 上下首 | 基础控制 |
| 播放模式 | 顺序 / 随机 / 单曲循环 |
| 播放队列 | 可拖拽排序，删除单曲 |
| 后台播放 | 熄屏/切 App 继续播放 |
| 系统媒体控件 | iOS 锁屏 / Android 通知栏 / 桌面媒体键 |
| 播放进度上报 | 每 10s 上报，退出时补报，用于跨端续播 |
| 全屏播放器 | 封面旋转动效 + 歌词联动 |

### 10.11 用户中心

| 功能 | 说明 |
|------|------|
| 收藏歌曲 / 专辑 / 歌手 | 云端同步，多端实时推送 |
| 播放历史 | 云端存储最近 500 条 |
| 自建歌单 | 创建 / 编辑 / 删除，云端同步 |
| 跨端续播 | 登录后自动从上次播放位置继续 |
| 设备管理 | 查看在线设备，主动注销 |

---

## 11. 平台差异化设计

### 11.1 Desktop（Windows / macOS / Linux）

- 侧边栏主导航 + 底部播放控制栏（含进度条 + 音量）
- 系统托盘图标（macOS Menu Bar / Windows System Tray）
- 快捷键：空格播放暂停 / ← → 跳转 10s / Ctrl+S 收藏
- 媒体键（F7/F8/F9）集成 `audio_service`，最小窗口宽度 900px

### 11.2 Mobile（Android & iOS）

- 底部 Tab 导航（首页 / 歌单 / 歌手 / 排行榜 / 我的）
- 迷你播放条悬浮于 Tab 上方
- 手势：左滑下一首，右滑上一首，下滑关闭全屏播放器
- iOS：AirPlay 支持；Android：WebSocket 后台时使用 FCM 维持推送

### 11.3 Android TV

- D-pad 焦点导航，遵循 Android TV 规范
- 侧边导航抽屉（左键呼出，默认收起）
- 卡片聚焦时放大 1.1x + 发光阴影
- 全屏视频/MV 播放为默认模式
- 字体、图标、间距放大 1.5x（10-foot UI）
- 搜索使用遥控器虚拟键盘

---

## 12. 项目目录结构

```
listen_stream/                    # 客户端（Flutter）
├── lib/
│   ├── core/
│   │   ├── network/              # Dio + WebSocket 封装
│   │   ├── auth/                 # JWT 存储、自动刷新、登录状态
│   │   ├── cache/                # 缓存策略抽象层（L1/L2/L3）
│   │   ├── player/               # 全局播放器 Service
│   │   ├── router/               # go_router 配置
│   │   ├── theme/                # Light / Dark / TV 主题
│   │   └── utils/
│   ├── data/
│   │   ├── models/               # JSON 序列化模型
│   │   ├── repositories/         # 数据仓库（网络 + 缓存）
│   │   └── local/                # Isar Schema + 本地操作
│   ├── features/
│   │   ├── auth/                 # 手机号登录 + 验证码 UI
│   │   ├── home/
│   │   ├── playlist/
│   │   ├── singer/
│   │   ├── ranking/
│   │   ├── radio/
│   │   ├── mv/
│   │   ├── album/
│   │   ├── search/
│   │   ├── lyric/
│   │   ├── player/
│   │   ├── library/              # 收藏 / 历史 / 自建歌单
│   │   └── profile/              # 用户中心 / 设备管理
│   ├── shared/
│   │   ├── widgets/
│   │   └── platform/             # TV 焦点 / 桌面快捷键
│   └── main.dart

listen_stream_server/             # 后端（Go 微服务 monorepo）
├── auth-svc/                     # 认证服务（:8001）
│   ├── cmd/server/main.go
│   ├── internal/
│   │   ├── handler/              # Gin 路由处理器
│   │   ├── service/              # 业务逻辑
│   │   ├── repo/                 # sqlc 生成的 DB 操作
│   │   └── middleware/           # JWT 验证、限流
│   ├── go.mod
│   └── Dockerfile
├── proxy-svc/                    # API 代理服务（:8002）
│   ├── cmd/server/main.go
│   ├── internal/
│   │   ├── handler/
│   │   ├── upstream/             # 第三方接口调用封装
│   │   └── cache/                # Redis 缓存 + ETag 逻辑
│   ├── go.mod
│   └── Dockerfile
├── sync-svc/                     # 同步服务（:8003）
│   ├── cmd/server/main.go
│   ├── internal/
│   │   ├── handler/
│   │   ├── service/
│   │   ├── repo/
│   │   ├── ws/                   # WebSocket Hub（gorilla/websocket）
│   │   └── cron/                 # Cookie 刷新定时任务
│   ├── go.mod
│   └── Dockerfile
├── admin-svc/                    # Admin 服务（:8004）
│   ├── cmd/server/main.go
│   ├── internal/
│   │   ├── handler/
│   │   ├── service/
│   │   └── repo/
│   ├── go.mod
│   └── Dockerfile
├── shared/
│   └── db/
│       ├── migrations/           # SQL 迁移文件（golang-migrate）
│       └── queries/              # sqlc SQL 查询定义
├── docker-compose.yml
└── .env.example

listen_stream_admin/              # Admin 控制台（Next.js）
├── app/
│   ├── (auth)/login/
│   ├── (auth)/setup/             # 首次初始化向导
│   ├── dashboard/
│   ├── api-config/               # 第三方 API 配置
│   ├── jwt-config/
│   ├── users/
│   ├── sms-config/
│   └── logs/
└── components/
```

---

## 13. 数据库模型（核心）

使用 **golang-migrate** 管理迁移，**sqlc** 从 SQL 查询生成类型安全的 Go 代码，不使用 ORM。

```sql
-- migrations/001_init.up.sql

CREATE TYPE role AS ENUM ('USER', 'ADMIN', 'SUPER_ADMIN');

CREATE TABLE users (
  id          TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  phone       TEXT UNIQUE NOT NULL,           -- E.164 格式
  role        role NOT NULL DEFAULT 'USER',
  disabled    BOOLEAN NOT NULL DEFAULT FALSE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE devices (
  id             TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  user_id        TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  device_id      TEXT UNIQUE NOT NULL,        -- 客户端生成的 UUID，不可变
  platform       TEXT NOT NULL,               -- android|ios|desktop|tv
  rt_hash        TEXT NOT NULL,               -- SHA-256(refresh_token)，审计用
  last_active_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE system_configs (
  key         TEXT PRIMARY KEY,               -- USER_JWT_SECRET / API_BASE_URL 等
  value       TEXT NOT NULL,                  -- AES-256-GCM 密文（base64）
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_by  TEXT NOT NULL
);

CREATE TABLE admin_users (
  id            TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  username      TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,               -- Argon2id
  role          role NOT NULL DEFAULT 'ADMIN',
  totp_secret   TEXT,                        -- 可选
  disabled      BOOLEAN NOT NULL DEFAULT FALSE,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE favorites (
  id         TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  user_id    TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  type       TEXT NOT NULL,                  -- song|album|singer
  target_id  TEXT NOT NULL,                  -- 第三方平台 ID，不存元数据
  deleted_at TIMESTAMPTZ,                    -- 软删除，用于 /user/sync
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (user_id, type, target_id)
);
CREATE INDEX ON favorites (user_id, type);

CREATE TABLE history (
  id         TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  user_id    TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  song_mid   TEXT NOT NULL,                  -- 第三方 song_mid，不存元数据
  progress   INT NOT NULL DEFAULT 0,         -- 播放进度（秒）
  played_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX ON history (user_id, played_at DESC);

CREATE TABLE user_playlists (
  id         TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  user_id    TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name       TEXT NOT NULL,
  deleted_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE playlist_songs (
  id          TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  playlist_id TEXT NOT NULL REFERENCES user_playlists(id) ON DELETE CASCADE,
  song_mid    TEXT NOT NULL,                 -- 第三方 song_mid
  sort_order  INT NOT NULL,
  added_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (playlist_id, song_mid)
);
CREATE INDEX ON playlist_songs (playlist_id, sort_order);

CREATE TABLE operation_logs (
  id         TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  admin_id   TEXT NOT NULL,
  action     TEXT NOT NULL,
  target_id  TEXT,
  before     TEXT,                           -- 脱敏后变更前值
  after      TEXT,                           -- 脱敏后变更后值
  ip         TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

**sqlc 生成的 Go 结构体（示例）**：

```go
// 由 sqlc generate 自动生成，位于各服务 internal/repo/ 目录
type User struct {
    ID        string
    Phone     string
    Role      RoleType
    Disabled  bool
    CreatedAt time.Time
    UpdatedAt time.Time
}

type Device struct {
    ID           string
    UserID       string
    DeviceID     string
    Platform     string
    RtHash       string
    LastActiveAt time.Time
    CreatedAt    time.Time
}

type Favorite struct {
    ID        string
    UserID    string
    Type      string
    TargetID  string
    DeletedAt *time.Time
    CreatedAt time.Time
}

type PlaylistSong struct {
    ID         string
    PlaylistID string
    SongMid    string
    SortOrder  int32
    AddedAt    time.Time
}
```

---

## 14. 开发阶段规划

### Phase 1 — 后端基础设施（Week 1-2）

- [ ] Fastify 项目初始化（TypeScript + Prisma + PostgreSQL + Redis）
- [ ] 数据库 Schema 设计与初始 Migration
- [ ] 动态配置系统（AES-256 加密存储）
- [ ] JWT 签发 / 刷新 / 验证中间件
- [ ] RBAC 权限中间件
- [ ] SMS 验证码接口（含发送频率限制）

### Phase 2 — Admin 控制台（Week 3-4）

- [ ] Next.js Admin 项目初始化
- [ ] 首次部署初始化向导（步骤 1-4）
- [ ] Admin 登录（用户名 + 密码 + 可选 TOTP）
- [ ] 第三方 API 配置管理页（含连通性测试）
- [ ] JWT 配置管理页
- [ ] SMS 配置管理页
- [ ] 用户管理页（RBAC 分权展示）
- [ ] 仪表盘 + 操作日志

### Phase 3 — API 代理层 + 同步服务（Week 5-6）

- [ ] 第三方接口代理转发（全模块）
- [ ] Redis 服务端缓存（按模块配置 TTL）
- [ ] ETag 响应头支持（客户端 304 复用）
- [ ] 用户数据同步接口（收藏 / 历史 / 歌单 / 播放进度）
- [ ] WebSocket 实时推送服务
- [ ] 离线变更拉取接口（`GET /user/sync?since=`）
- [ ] Cookie 自动刷新 Cron 任务

### Phase 4 — 客户端骨架（Week 7-8）

- [ ] Flutter 多平台工程初始化
- [ ] 网络层封装（JWT 自动刷新拦截器 + ETag）
- [ ] 本地缓存层（Isar + 分级缓存策略）
- [ ] WebSocket 同步客户端
- [ ] 路由体系（go_router）+ 主题系统
- [ ] 手机号登录 UI + 验证码倒计时
- [ ] 全局播放器（just_audio + audio_service）

### Phase 5 — 主要功能页面（Week 9-12）

- [ ] 首页（Banner + 推荐，懒加载 Section）
- [ ] 歌单：分类 + 列表 + 详情
- [ ] 歌手：筛选 + 列表 + 详情（Tab 懒初始化）
- [ ] 排行榜：分类 + 详情
- [ ] 搜索：热词 + 多类型结果
- [ ] 歌词：滚动同步 + 翻译切换
- [ ] 播放器 UI（迷你条 + 全屏）
- [ ] 用户中心（收藏 / 历史 / 设备管理）

### Phase 6 — 补充功能（Week 13-14）

- [ ] 电台模块
- [ ] MV 模块（视频播放器集成）
- [ ] 专辑详情
- [ ] 自建歌单管理
- [ ] 跨端续播（进度同步）

### Phase 7 — Android TV 适配（Week 15-16）

- [ ] TV 焦点导航框架（FocusNode + FocusTraversalGroup）
- [ ] TV 专属布局（10-foot UI）
- [ ] 遥控器快捷键映射
- [ ] TV 测试（物理设备 / 模拟器）

### Phase 8 — 质量 & 发布（Week 17-18）

- [ ] 单元测试 + Widget 测试
- [ ] 性能优化（列表帧率、缓存命中率、内存）
- [ ] 安全审计（JWT 配置、API 密钥暴露面检查）
- [ ] 桌面端打包（MSIX / DMG / AppImage）
- [ ] 移动端打包（APK / AAB / IPA）
- [ ] Android TV APK 打包与上架准备
- [ ] Admin 控制台生产部署（nginx 反代 + IP 白名单）

---

## 15. 依赖清单

### 15.1 Flutter 客户端（pubspec.yaml）

```yaml
dependencies:
  flutter:
    sdk: flutter
  dio: ^5.x
  retrofit: ^4.x
  json_annotation: ^4.x
  web_socket_channel: ^3.x
  flutter_secure_storage: ^9.x
  flutter_riverpod: ^2.x
  riverpod_annotation: ^2.x
  go_router: ^14.x
  just_audio: ^0.9.x
  audio_service: ^0.18.x
  just_audio_background: ^0.0.x
  video_player: ^2.x
  chewie: ^1.x
  isar: ^3.x
  isar_flutter_libs: ^3.x
  shared_preferences: ^2.x
  cached_network_image: ^3.x
  flutter_cache_manager: ^3.x
  freezed_annotation: ^2.x
  equatable: ^2.x
  connectivity_plus: ^6.x

dev_dependencies:
  build_runner: ^2.x
  json_serializable: ^6.x
  freezed: ^2.x
  retrofit_generator: ^8.x
  riverpod_generator: ^2.x
  isar_generator: ^3.x
  flutter_test:
    sdk: flutter
```

### 15.2 后端（各服务 go.mod 核心依赖）

**公共依赖（4 个服务均使用）**：

```
github.com/gin-gonic/gin v1.10.x
github.com/golang-jwt/jwt/v5 v5.x
github.com/redis/go-redis/v9 v9.x
github.com/jackc/pgx/v5 v5.x
go.uber.org/zap v1.x
github.com/spf13/viper v1.x
```

**auth-svc 额外依赖**：

```
golang.org/x/crypto v0.x              # argon2（Admin 密码），bcrypt 备用
github.com/xlzd/gotp v0.x             # TOTP 验证
```

**sync-svc 额外依赖**：

```
github.com/gorilla/websocket v1.x      # WebSocket
github.com/robfig/cron/v3 v3.x        # Cookie 刷新定时任务
```

**DB 工具（开发依赖，不进 go.mod）**：

```
github.com/sqlc-dev/sqlc              # sqlc generate（代码生成）
github.com/golang-migrate/migrate     # 数据库迁移
```

---

## 16. 风险与注意事项

| 风险点 | 说明 | 缓解措施 |
|--------|------|----------|
| 播放 URL 时效性 | 第三方播放 URL 通常数分钟内失效 | 每次播放前实时获取，绝不缓存 |
| Cookie 失效 | 第三方登录 Cookie 可能随时失效 | Admin 仪表盘监控、配置自动刷新 Cron、失效告警 |
| SMS 费用与滥用 | 恶意频繁发送验证码消耗费用 | 同号 60s 限频 + IP 每日上限 + 验证码 5min 过期 |
| JWT Secret 泄露 | 密钥泄露导致全量 Token 伪造 | 存 DB 加密，Admin 修改后强制全员下线，记录操作日志 |
| 带宽超标 | 大量客户端频繁请求超出服务器带宽 | 服务端 Redis 缓存 + 客户端本地缓存 + ETag 304 + 限流 |
| 多端同步冲突 | 多端同时操作产生数据冲突 | Last-Write-Wins + 服务端时间戳权威，实时推送覆盖 |
| Android TV 焦点 | Flutter TV 焦点链容易断裂 | 使用 `FocusTraversalGroup` 显式管理，充分真机测试 |
| 大列表性能 | 排行榜/歌手列表可能数千条 | `ListView.builder` + 分页懒加载，禁止全量渲染 |
| Admin 入口安全 | Admin 控制台被暴力破解 | 独立域名 + nginx IP 白名单 + 登录失败次数锁定 + TOTP |
