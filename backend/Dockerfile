# Stage 1: Build
FROM golang:1.26-alpine AS builder

WORKDIR /app

RUN apk --no-cache add ca-certificates

COPY go.mod .

RUN go mod tidy

COPY . .

RUN CGO_ENABLED=0 GOOS=linux go build -o skillpulse .

# Stage 2: Run
FROM gcr.io/distroless/static-debian12

WORKDIR /app

COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

COPY --from=builder /app/skillpulse .

USER nonroot

EXPOSE 8080

CMD ["./skillpulse"]
