-- ============================================================
-- operation_logs 查询（追加写，不可修改/删除）
-- 使用服务：admin-svc（写）、admin-svc（读查询）
-- ============================================================

-- name: CreateOperationLog :one
INSERT INTO operation_logs (admin_id, action, target_id, before_val, after_val, ip)
VALUES ($1, $2, $3, $4, $5, $6)
RETURNING *;

-- name: ListOperationLogs :many
SELECT * FROM operation_logs
WHERE (@action::text = '' OR action = @action)
ORDER BY created_at DESC
LIMIT $1 OFFSET $2;

-- name: CountOperationLogs :one
SELECT COUNT(*) FROM operation_logs
WHERE (@action::text = '' OR action = @action);
