FROM golang:1.23-alpine AS builder
WORKDIR /src
COPY go.work go.work.sum ./
COPY shared/go/ shared/go/
COPY sync-svc/ sync-svc/
RUN go build -o /bin/sync-svc ./sync-svc/cmd/server

FROM alpine:3.20
RUN addgroup -S app && adduser -S app -G app
COPY --from=builder /bin/sync-svc /bin/sync-svc
USER app
EXPOSE 8003
ENTRYPOINT ["/bin/sync-svc"]
