# https://github.com/jtagcat/dotfiles/blob/main/scripts/template/gobuild.Dockerfile
FROM golang:1.23 AS builder
WORKDIR /wd

COPY go.mod go.sum ./
RUN go mod download

COPY *.go ./
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o miniflux-lister

FROM alpine
WORKDIR /wd

COPY --from=builder /wd/miniflux-lister ./
CMD ["./miniflux-lister"]
