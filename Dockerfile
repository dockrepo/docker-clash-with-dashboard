FROM golang:alpine as builder1

RUN apk add --no-cache make git && \
    wget -O /Country.mmdb https://github.com/Dreamacro/maxmind-geoip/releases/latest/download/Country.mmdb && \
    wget -O /qemu-aarch64-static https://github.com/multiarch/qemu-user-static/releases/latest/download/qemu-aarch64-static && \
    chmod +x /qemu-aarch64-static

WORKDIR /clash-src

RUN git clone https://github.com/Dreamacro/clash.git /clash-src

RUN go mod download && \
    make linux-armv8 && \
    mv ./bin/clash-linux-armv8 /clash

# step 2

FROM node:latest as builder2

LABEL maintainer "zyao89 <zyao89@gmail.com>"

WORKDIR /app
RUN git clone https://github.com/Dreamacro/clash-dashboard.git .
RUN yarn && yarn run build

# step 3

FROM arm64v8/alpine:latest

COPY --from=builder1 /qemu-aarch64-static /usr/bin/
COPY --from=builder1 /Country.mmdb /root/.config/clash/
COPY --from=builder1 /clash /
COPY --from=builder2 /app/dist /ui
RUN apk add --no-cache ca-certificates

WORKDIR /

VOLUME ["/root/.config/clash"]

EXPOSE 7890
EXPOSE 7891
EXPOSE 80

ENTRYPOINT ["/clash"]
HEALTHCHECK --interval=5s --timeout=1s CMD ps | grep darkhttpd | grep -v grep || exit 1
