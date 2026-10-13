FROM golang:1.24-alpine AS builder
ENV CGO_ENABLED=0
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN go build -o papope-relay ./cmd

FROM scratch
COPY --from=builder /app/papope-relay /papope-relay
COPY --from=alpine:latest /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
ENTRYPOINT ["/papope-relay"]
