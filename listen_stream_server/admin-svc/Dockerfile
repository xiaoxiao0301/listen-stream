FROM golang:1.23-alpine AS builder
WORKDIR /src
COPY go.work go.work.sum ./
COPY shared/go/ shared/go/
COPY admin-svc/ admin-svc/
RUN go build -o /bin/admin-svc ./admin-svc/cmd/server

FROM alpine:3.20
RUN addgroup -S app && adduser -S app -G app
COPY --from=builder /bin/admin-svc /bin/admin-svc
USER app
EXPOSE 8004
ENTRYPOINT ["/bin/admin-svc"]
