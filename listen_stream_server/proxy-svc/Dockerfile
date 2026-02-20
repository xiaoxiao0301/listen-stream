FROM golang:1.23-alpine AS builder
WORKDIR /src
COPY go.work go.work.sum ./
COPY shared/go/ shared/go/
COPY proxy-svc/ proxy-svc/
RUN go build -o /bin/proxy-svc ./proxy-svc/cmd/server

FROM alpine:3.20
RUN addgroup -S app && adduser -S app -G app
COPY --from=builder /bin/proxy-svc /bin/proxy-svc
USER app
EXPOSE 8002
ENTRYPOINT ["/bin/proxy-svc"]
