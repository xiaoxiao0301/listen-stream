# listen-stream 启动指南（Docker）

## 前置条件

- Docker 24+
- Docker Compose v2（`docker compose` 命令）
- `openssl`（生成加密密钥）

---

## 一、准备环境变量

```bash
cd /Users/aji/listen-stream/listen_stream_server

cp .env.example .env
```

编辑 `.env`，填入以下必填项：

```bash
# 1. 生成 CONFIG_ENCRYPTION_KEY（必须 64 位小写十六进制）
openssl rand -hex 32
# 将输出填入 .env：
# CONFIG_ENCRYPTION_KEY=<上面生成的值>

# 2. 填写上游音乐 API 地址
# UPSTREAM_API_BASE_URL=https://your-music-api.com
```

`.env` 最终内容示意：

```dotenv
DATABASE_URL=postgres://listen:listen@localhost:5432/listen_stream?sslmode=disable
REDIS_URL=redis://localhost:6379/0
CONFIG_ENCRYPTION_KEY=a1b2c3d4...（64位）
UPSTREAM_API_BASE_URL=https://your-music-api.com
```

> `DATABASE_URL` 和 `REDIS_URL` 在容器内会被 `docker-compose.yml` 自动覆盖为内网地址，本地值无需修改。

---

## 二、构建并启动所有服务

```bash
cd /Users/aji/listen-stream/listen_stream_server

docker compose up --build -d
```

启动顺序由健康检查保证：

```
postgres:15  ──健康──▶  auth-svc  (:8001)
redis:7      ──健康──▶  proxy-svc (:8002)
                        sync-svc  (:8003)
                        admin-svc (:8004)
```

查看启动状态：

```bash
docker compose ps
docker compose logs -f          # 全部日志
docker compose logs -f auth-svc # 单服务日志
```

---

## 三、运行数据库迁移（首次启动必须）

等 postgres 健康后执行：

```bash
docker compose exec -T postgres \
  psql -U listen -d listen_stream \
  < shared/db/migrations/001_init.up.sql
```

验证迁移成功：

```bash
docker compose exec postgres \
  psql -U listen -d listen_stream -c "\dt"
```

---

## 四、初始化管理员账号（首次启动必须）

```bash
docker compose run --rm admin-svc \
  /bin/sh -c "go run ./cmd/reset_admin --username=admin --password='YourStrongPass!'"
```

或者直接调用初始化接口（系统未初始化时可用）：

```bash
curl -X POST http://localhost:8004/admin/setup/init \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"YourStrongPass!"}'
```

---

## 五、配置运行时密钥（首次启动必须）

以下配置存储在 `system_configs` 表（AES-256-GCM 加密），不是环境变量。  
登录管理后台 `http://localhost:8004` 后，在「系统配置」页面填入：

| Key | 说明 | 示例 |
|-----|------|------|
| `USER_JWT_SECRET` | 用户 Token 签名密钥 | `openssl rand -hex 32` 的输出 |
| `ADMIN_JWT_SECRET` | 管理员 Token 签名密钥 | `openssl rand -hex 32` 的输出 |
| `SMS_PROVIDER_KEY` | 短信服务 API Key | 向短信服务商申请 |
| `ACCESS_TOKEN_TTL` | Access Token 有效期（秒） | `7200` |
| `REFRESH_TOKEN_TTL` | Refresh Token 有效期（秒） | `2592000` |
| `SMS_DAILY_LIMIT` | 每号码每日发码上限 | `5` |
| `PROXY_CACHE_TTL` | 代理缓存 TTL（秒） | `300` |

---

## 六、服务端口速查

| 服务 | 容器内端口 | 宿主机端口 | 说明 |
|------|-----------|-----------|------|
| postgres | 5432 | **5432** | PostgreSQL 15 |
| redis | 6379 | **6379** | Redis 7 |
| auth-svc | 8001 | **8001** | 用户认证（短信登录、JWT） |
| proxy-svc | 8002 | **8002** | 音乐 API 代理（带缓存） |
| sync-svc | 8003 | **8003** | 用户数据同步 + WebSocket |
| admin-svc | 8004 | **8004** | 管理后台 API |

---

## 七、常用运维命令

```bash
# 停止所有服务（保留数据卷）
docker compose down

# 停止并清除数据卷（重置数据库和 Redis）
docker compose down -v

# 重新构建某个服务
docker compose up --build auth-svc -d

# 进入容器 shell（调试用）
docker compose exec auth-svc sh

# 查看资源占用
docker compose stats
```

---

## 八、验证启动成功

```bash
# auth-svc 健康检查
curl http://localhost:8001/health

# proxy-svc 健康检查
curl http://localhost:8002/health

# sync-svc 健康检查
curl http://localhost:8003/health

# admin-svc 健康检查
curl http://localhost:8004/health
```

所有接口返回 `200 OK` 表示启动成功。

---

## 附：完整快速启动脚本

```bash
#!/usr/bin/env bash
set -e

cd "$(dirname "$0")/listen_stream_server"

# 1. 生成 .env
if [ ! -f .env ]; then
  cp .env.example .env
  KEY=$(openssl rand -hex 32)
  sed -i '' "s/<REPLACE_WITH_64_HEX_CHARS>/$KEY/" .env
  echo "[INFO] .env 已生成，请填写 UPSTREAM_API_BASE_URL"
  exit 1
fi

# 2. 启动
docker compose up --build -d

# 3. 等待 postgres 就绪
echo "[INFO] 等待 postgres 健康..."
until docker compose exec -T postgres pg_isready -U listen -d listen_stream &>/dev/null; do
  sleep 2
done

# 4. 迁移
docker compose exec -T postgres \
  psql -U listen -d listen_stream \
  < shared/db/migrations/001_init.up.sql && \
  echo "[INFO] 数据库迁移完成"

echo "[OK] 所有服务已启动"
docker compose ps
```

将脚本保存为项目根目录的 `start.sh`，`chmod +x start.sh` 后执行 `./start.sh` 即可一键启动。
