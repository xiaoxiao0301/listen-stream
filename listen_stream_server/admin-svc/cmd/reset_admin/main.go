// cmd/reset_admin/main.go — CLI tool to reset or create the super_admin account.
//
// Usage:
//
//	export DATABASE_URL="postgres://..."
//	export CONFIG_ENCRYPTION_KEY="<64 hex chars>"
//	./reset_admin --username=admin --password='Str0ng!Password'
//
// The tool uses UpsertAdmin so it is safe to run multiple times.
package main

import (
	"context"
	"flag"
	"log"
	"os"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/joho/godotenv"

	"listen-stream/admin-svc/internal/repo"
	"listen-stream/admin-svc/internal/service"
)

func main() {
	_ = godotenv.Load()

	username := flag.String("username", "admin", "super admin username")
	password := flag.String("password", "", "super admin password (required)")
	flag.Parse()

	if *password == "" {
		log.Fatal("--password is required")
	}

	ctx := context.Background()

	pool, err := pgxpool.New(ctx, mustEnv("DATABASE_URL"))
	if err != nil {
		log.Fatalf("connect db: %v", err)
	}
	defer pool.Close()

	// Hash password with argon2id
	hash, err := service.HashPassword(*password)
	if err != nil {
		log.Fatalf("hash password: %v", err)
	}

	q := repo.New(pool)
	admin, err := q.UpsertAdmin(ctx, repo.UpsertAdminParams{
		Username:     *username,
		PasswordHash: hash,
		Role:         repo.UserRoleSUPERADMIN,
	})
	if err != nil {
		log.Fatalf("upsert admin: %v", err)
	}

	log.Printf("已重置超级管理员账号 (id=%s username=%s)，请立即登录并修改密码", admin.ID, admin.Username)
}

func mustEnv(key string) string {
	v := os.Getenv(key)
	if v == "" {
		log.Fatalf("required env %s is not set", key)
	}
	return v
}
