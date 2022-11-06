# https://github.com/jtagcat/dotfiles/blob/main/scripts/template/gobuild.Dockerfile
# non-working workarounds: https://gist.github.com/jtagcat/189b2fd239687ab700f54faa46907df4

# TODO: set go version (1.19)
FROM golang:1.19 AS builder
WORKDIR /wd

COPY go.mod go.sum ./
RUN go mod download

# https://github.com/docker/docker.github.io/issues/14609
# TODO: comment 2nd line if you have '.go' files in only root of project
COPY *.go ./
COPY . ./
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o app

# https://docs.docker.com/develop/develop-images/multistage-build/#use-multi-stage-builds
FROM alpine
# TODO: change URL:
LABEL org.opencontainers.image.source="https://github.com/jtagcat/CHANGEME"
WORKDIR /wd
#RUN apk --no-cache add ca-certificates

COPY --from=builder /wd/app ./
CMD ["./app"]
