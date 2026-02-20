# Listen Stream — WebSocket 事件协议规范

> 版本：1.0.0  
> 生成日期：2026-02-20  
> WebSocket 服务由 **sync-svc** (:8003) 提供，路径为 `ws://host:8003/ws`

---

## 1. 连接建立与鉴权

### 1.1 升级方式

客户端发起 WebSocket Upgrade 请求时，**在 Query String 中携带 Access Token**：

```
ws://host:8003/ws?token=<accessToken>&device_id=<deviceId>
```

| 参数        | 必填 | 说明                                  |
|-----------|------|-------------------------------------|
| `token`   | ✅   | 用户 AT，Claims `aud = ["user"]`      |
| `device_id` | ✅  | 该连接关联的设备 ID，用于多设备推送时排除自身           |

> **不使用 HTTP Authorization 头**，因为 WebSocket 浏览器/原生客户端的升级请求无法设置自定义 Header。

### 1.2 鉴权流程

```
Client                              Server
  |                                   |
  |--- WS Upgrade (?token=...) -----> |
  |                                   |-- jwtSvc.VerifyUserToken(token)
  |                                   |   + 检查 aud = "user"
  |                                   |   + 检查 User.disabled
  |                                   |
  |                       [成功] ----> hub.Register(userID, deviceID, conn)
  |<--- 101 Switching Protocols ------|
  |                                   |
  |                       [失败] ----> ws.CloseMessage(code=4001, "UNAUTHORIZED")
  |<--- Close(4001) ------------------|
```

### 1.3 关闭码规范

| Code  | 含义                    |
|-------|------------------------|
| 4001  | 鉴权失败（Token无效/aud错误/用户被禁） |
| 4002  | 服务端主动断开（维护/重启）  |
| 1000  | 正常关闭（客户端主动断开）  |
| 1001  | 服务端关闭（进程退出）      |
| 1008  | 消息格式错误（无法解析 JSON）|

---

## 2. 消息格式（统一）

所有 WebSocket 消息（双向）均使用 **JSON 文本帧**，格式如下：

```json
{
  "event": "<event_type>",
  "payload": { ... },
  "ts": "2026-02-20T12:00:00.000Z"
}
```

| 字段      | 类型     | 必填 | 说明                            |
|---------|--------|------|---------------------------------|
| `event` | string | ✅   | 事件类型标识符，见下方各节枚举       |
| `payload`| object | ✅   | 事件数据，各事件结构不同（见下方）   |
| `ts`    | string | ✅   | ISO 8601 UTC 时间戳，服务端生成时间 |

> **服务端**：所有下发消息的 `ts` 均由服务端生成，客户端不可信任本地时钟作为 `ts`。  
> **客户端**：上行消息的 `ts` 由客户端生成，服务端仅用于日志，不参与业务逻辑。

---

## 3. 事件类型：服务端 → 客户端（推送）

### 3.1 收藏变更事件

#### `favorite.added`

用户在其他设备添加收藏后，向**除操作设备外**的所有在线设备推送。

```json
{
  "event": "favorite.added",
  "payload": {
    "id": "fav_01JQXYZ",
    "type": "song",
    "targetId": "003Qui1q2u1Zho",
    "createdAt": "2026-02-20T12:00:00Z"
  },
  "ts": "2026-02-20T12:00:00.123Z"
}
```

| 字段         | 类型                        | 说明                          |
|------------|---------------------------|-------------------------------|
| `id`       | string                    | 收藏记录 ID                    |
| `type`     | `"song"｜"album"｜"singer"` | 收藏类型                       |
| `targetId` | string                    | 第三方 song_mid/album_mid/singer_mid |
| `createdAt`| string (ISO 8601)         | 服务端创建时间                  |

#### `favorite.removed`

```json
{
  "event": "favorite.removed",
  "payload": {
    "id": "fav_01JQXYZ",
    "type": "song",
    "targetId": "003Qui1q2u1Zho"
  },
  "ts": "2026-02-20T12:00:00.123Z"
}
```

---

### 3.2 歌单变更事件

#### `playlist.created`

```json
{
  "event": "playlist.created",
  "payload": {
    "id": "pl_01JRABCD",
    "name": "我的最爱",
    "createdAt": "2026-02-20T12:00:00Z"
  },
  "ts": "2026-02-20T12:00:00.123Z"
}
```

#### `playlist.updated`

```json
{
  "event": "playlist.updated",
  "payload": {
    "id": "pl_01JRABCD",
    "name": "我的最爱（已更名）",
    "updatedAt": "2026-02-20T12:05:00Z"
  },
  "ts": "2026-02-20T12:05:00.001Z"
}
```

> `name` 为可选字段，未来若扩展其他可更新属性也通过此事件下发。

#### `playlist.deleted`

```json
{
  "event": "playlist.deleted",
  "payload": {
    "id": "pl_01JRABCD"
  },
  "ts": "2026-02-20T12:06:00.001Z"
}
```

#### `playlist.songs_changed`

```json
{
  "event": "playlist.songs_changed",
  "payload": {
    "playlistId": "pl_01JRABCD",
    "action": "add",
    "songMid": "003Qui1q2u1Zho",
    "sortOrder": 3
  },
  "ts": "2026-02-20T12:07:00.001Z"
}
```

| 字段          | 类型                | 说明                        |
|-------------|-------------------|-----------------------------|
| `action`    | `"add"｜"remove"` | 操作类型                     |
| `sortOrder` | integer (可选)     | 仅 `action=add` 时返回       |

---

### 3.3 播放进度事件

#### `progress.updated`

同一账号在另一设备更新播放进度后下发，供客户端同步续播位置。

```json
{
  "event": "progress.updated",
  "payload": {
    "songMid": "003Qui1q2u1Zho",
    "progress": 124,
    "updatedAt": "2026-02-20T12:10:00Z"
  },
  "ts": "2026-02-20T12:10:00.001Z"
}
```

---

### 3.4 设备与安全事件

#### `device.kicked`

当前连接被强制下线。客户端收到后**必须**清除本地所有 Token 并跳转登录页，**不得**尝试重连。

```json
{
  "event": "device.kicked",
  "payload": {
    "reason": "max_devices"
  },
  "ts": "2026-02-20T12:00:00.001Z"
}
```

| `reason` 值      | 触发场景                                |
|-----------------|----------------------------------------|
| `max_devices`   | 新设备登录，超过最大设备数，本设备被踢出      |
| `admin_force`   | 管理员主动吊销该设备或禁用该用户            |
| `jwt_rotated`   | USER_JWT_SECRET 被轮换，全量下线          |

#### `config.jwt_rotated`

仅在 `USER_JWT_SECRET` 轮换时触发，提示客户端重新登录。通常紧跟在 `device.kicked(jwt_rotated)` 之前，或单独下发给无活跃设备的用户在下次连接时提示。

```json
{
  "event": "config.jwt_rotated",
  "payload": {
    "message": "re-login required"
  },
  "ts": "2026-02-20T12:00:00.001Z"
}
```

---

## 4. 事件类型：客户端 → 服务端

> **设计原则**：所有数据写操作通过 HTTPS REST 完成，WebSocket 仅用于**接收推送**和**保活**。客户端不通过 WS 发送业务数据。

### 4.1 `ping`（保活）

客户端在**前台活跃时**，若 30s 内未收到任何服务端消息，主动发送：

```json
{
  "event": "ping",
  "payload": {},
  "ts": "2026-02-20T12:10:30.000Z"
}
```

服务端响应：

```json
{
  "event": "pong",
  "payload": {
    "serverTime": "2026-02-20T12:10:30.123Z"
  },
  "ts": "2026-02-20T12:10:30.123Z"
}
```

> 客户端可利用 `pong.payload.serverTime` 与本地时钟做偏差校正（RTT/2 估算）。

---

## 5. 保活与重连策略

### 5.1 客户端保活职责

```
前台活跃状态：
  - 每次收到任何服务端消息，重置 30s 计时器
  - 30s 无消息 → 发送 ping
  - 若 10s 内未收到 pong → 判断连接断线，触发重连

后台/息屏状态：
  - 停止 ping（节省电量）
  - 回到前台时如连接已断 → 立即重连 + 调用 GET /user/sync?since=<lastSyncTime> 拉取离线增量
```

### 5.2 指数退避重连算法

```
初始等待时间  : 1s
最大等待时间  : 30s
退避因子      : 2.0（每次失败翻倍）
随机抖动      : ±20%（防止大量设备同时重连踩踏）

伪代码：
  attempt = 0
  while not connected:
    wait = min(1 * 2^attempt, 30) * (0.8 + random()*0.4)
    sleep(wait)
    try connect()
    attempt += 1
    if attempt > 20: stop retrying, show "network error" UI
```

### 5.3 重连后 Token 刷新

```
reconnect() 流程：
  1. 使用当前 accessToken 尝试建立连接
  2. 若服务端返回 close(4001)：
       a. 使用本地 refreshToken 调用 POST /auth/refresh
       b. 刷新成功 → 存储新 Token → 使用新 accessToken 重建连接
       c. 刷新失败（TOKEN_REUSED / TOKEN_EXPIRED）→ 清除所有本地 Token → 跳转登录页
  3. 连接成功后 → 调用 GET /user/sync?since=<lastSyncTime> 拉取离线增量
```

### 5.4 `device.kicked` 处理

```
当客户端收到 device.kicked 事件：
  1. 立即关闭 WS 连接（本地主动 close）
  2. 清除安全存储中的 accessToken + refreshToken + deviceId
  3. 清除本地离线缓存（Isar DB，可选：保留歌单/收藏数据供离线查看）
  4. 取消所有进行中的 HTTP 请求
  5. 停止播放器
  6. 跳转到登录页，展示对应原因文案：
       max_devices  → "您的账号已在新设备登录，当前设备已下线"
       admin_force  → "您的账号已被管理员下线"
       jwt_rotated  → "系统安全更新，请重新登录"
  7. 不执行任何重连逻辑
```

---

## 6. 多实例广播架构

> 本节为 sync-svc 内部实现说明，用于指导 Prompt A.6 实现。

```
                 ┌─────────────────────┐
                 │   Redis Pub/Sub      │
                 │  channel: ws:user:{uid}│
                 └──────┬──────┬───────┘
                        │      │
               ┌────────▼──┐  ┌▼────────────┐
               │ sync-svc  │  │  sync-svc   │  (多实例)
               │ instance 1│  │  instance 2 │
               └───┬───────┘  └──────┬──────┘
                   │                  │
             WS连接池A            WS连接池B
        (设备A, 设备B)          (设备C, 设备D)
```

推送流程：
1. HTTP 写操作（如 POST /user/favorites）触发 `rdb.Publish(ws:user:{uid}, eventJSON)`
2. 所有 sync-svc 实例订阅各自用户频道，收到消息后本地广播
3. 发起请求的设备（excludeDeviceID）在本地广播时跳过，省去重复通知

---

## 7. 错误处理

| 场景                          | 处理方式                                  |
|-----------------------------|------------------------------------------|
| 收到无法解析的 JSON 消息         | 服务端 close(1008)，客户端忽略并记录日志     |
| 客户端发 send 缓冲区满           | 服务端断开连接（goroutine 超时检测），close(1001)|
| 服务端推送超时（单条 > 5s）       | 服务端断开并从 hub 注销                    |
| 客户端收到未知 event 类型        | 忽略，不报错，记录调试日志（forward compatibility）|
| WS 连接建立但 30s 未发任何消息   | 服务端断开（空闲超时），客户端触发重连逻辑     |

---

## 8. 事件汇总表

| 方向               | 事件名                   | 触发场景                         | 推送目标        |
|------------------|------------------------|----------------------------------|----------------|
| Server → Client  | `favorite.added`       | 添加收藏                          | 同用户其他设备  |
| Server → Client  | `favorite.removed`     | 删除收藏                          | 同用户其他设备  |
| Server → Client  | `playlist.created`     | 创建歌单                          | 同用户其他设备  |
| Server → Client  | `playlist.updated`     | 重命名歌单                        | 同用户其他设备  |
| Server → Client  | `playlist.deleted`     | 删除歌单                          | 同用户其他设备  |
| Server → Client  | `playlist.songs_changed`| 歌单增减歌曲                      | 同用户其他设备  |
| Server → Client  | `progress.updated`     | 更新播放进度                      | 同用户其他设备  |
| Server → Client  | `device.kicked`        | 设备被踢/用户被禁/密钥轮换          | 被踢设备       |
| Server → Client  | `config.jwt_rotated`   | USER_JWT_SECRET 轮换              | 所有在线设备   |
| Server → Client  | `pong`                 | 响应客户端 ping                   | 发起方         |
| Client → Server  | `ping`                 | 保活心跳（30s 无消息触发）          | 服务端（不广播）|
