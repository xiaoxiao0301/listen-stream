# auth-svc Dockerfile
# Multi-stage build: builder → minimal runtime image.
# Context: repository root (listen_stream_server/) so the Go workspace
# (go.work + shared/go) is available during build.

FROM golang:1.23-alpine AS builder

WORKDIR /src
COPY go.work go.work.sum ./
COPY shared/go/ shared/go/
COPY auth-svc/ auth-svc/

RUN go build -o /bin/auth-svc ./auth-svc/cmd/server

# ── Runtime ───────────────────────────────────────────────────────────────────
FROM alpine:3.20
RUN addgroup -S app && adduser -S app -G app
COPY --from=builder /bin/auth-svc /bin/auth-svc
USER app
EXPOSE 8001
ENTRYPOINT ["/bin/auth-svc"]
