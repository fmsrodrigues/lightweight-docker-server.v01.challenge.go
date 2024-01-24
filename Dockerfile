FROM golang:1.21.5-alpine as builder

WORKDIR /home/go

COPY . .
RUN go mod tidy
RUN go mod download
RUN go mod verify
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -C ./cmd/web -o server -ldflags="-w -s"

RUN apk add --no-cache upx
RUN upx --best ./cmd/web/server

RUN apk update && apk add --no-cache ca-certificates && update-ca-certificates

FROM scratch

ENV APP_HOME /home/go
WORKDIR "$APP_HOME"

COPY --from=builder "$APP_HOME"/.env $APP_HOME
COPY --from=builder "$APP_HOME"/cmd/web/server $APP_HOME

COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

EXPOSE 8080
CMD ["./server"]