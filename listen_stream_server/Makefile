SHELL := /bin/bash
.PHONY: infra infra-stop auth proxy sync admin dev dev-stop migrate

# ── Infrastructure ─────────────────────────────────────────────────────────────

## Start PostgreSQL + Redis in Docker (detached)
infra:
	docker compose -f docker-compose.dev.yml up -d
	@echo "Waiting for postgres..."
	@until docker compose -f docker-compose.dev.yml exec postgres pg_isready -U listen -q; do sleep 1; done
	@echo "✓ postgres ready"
	@echo "✓ redis ready"

## Stop infrastructure containers
infra-stop:
	docker compose -f docker-compose.dev.yml down

# ── Individual service hot-reload targets ──────────────────────────────────────

## auth-svc  :8001  (JWT, SMS, login)
auth:
	air -c .air.auth-svc.toml

## proxy-svc :8002  (music API proxy + cache)
proxy:
	air -c .air.proxy-svc.toml

## sync-svc  :8003  (WebSocket, favorites, history)
sync:
	air -c .air.sync-svc.toml

## admin-svc :8004  (admin panel backend)
admin:
	air -c .air.admin-svc.toml

# ── Combined dev target ────────────────────────────────────────────────────────
# Starts infra then all four services in parallel.
# Press Ctrl-C once to stop everything cleanly.

## Start everything (infra + all services with hot-reload)
dev: infra
	@mkdir -p tmp/logs
	@echo "Starting all services with air hot-reload..."
	@echo "  auth-svc  → :8001   (logs: tmp/logs/auth.log)"
	@echo "  proxy-svc → :8002   (logs: tmp/logs/proxy.log)"
	@echo "  sync-svc  → :8003   (logs: tmp/logs/sync.log)"
	@echo "  admin-svc → :8004   (logs: tmp/logs/admin.log)"
	@echo "Press Ctrl-C to stop all services."
	@trap 'kill 0' INT; \
	air -c .air.auth-svc.toml  2>&1 | tee tmp/logs/auth.log  | sed 's/^/[auth]  /' & \
	air -c .air.proxy-svc.toml 2>&1 | tee tmp/logs/proxy.log | sed 's/^/[proxy] /' & \
	air -c .air.sync-svc.toml  2>&1 | tee tmp/logs/sync.log  | sed 's/^/[sync]  /' & \
	air -c .air.admin-svc.toml 2>&1 | tee tmp/logs/admin.log | sed 's/^/[admin] /' & \
	wait

# ── Database migrations ────────────────────────────────────────────────────────

## Run all up migrations (requires golang-migrate: brew install golang-migrate)
migrate:
	migrate -path shared/db/migrations \
	        -database "postgres://listen:listen@localhost:5432/listen_stream?sslmode=disable" \
	        up

## Roll back all migrations
migrate-down:
	migrate -path shared/db/migrations \
	        -database "postgres://listen:listen@localhost:5432/listen_stream?sslmode=disable" \
	        down

# ── Help ───────────────────────────────────────────────────────────────────────
help:
	@echo ""
	@echo "Usage:"
	@echo "  make infra        Start PostgreSQL + Redis in Docker"
	@echo "  make dev          Start infra + all 4 services with air hot-reload"
	@echo "  make auth         Run only auth-svc  (:8001)"
	@echo "  make proxy        Run only proxy-svc (:8002)"
	@echo "  make sync         Run only sync-svc  (:8003)"
	@echo "  make admin        Run only admin-svc (:8004)"
	@echo "  make migrate      Apply DB migrations"
	@echo "  make infra-stop   Stop Docker containers"
	@echo ""
