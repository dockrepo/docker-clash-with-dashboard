FROM node:latest as builder

WORKDIR /app
RUN git clone https://github.com/Dreamacro/clash-dashboard.git .
RUN yarn && yarn run build

# step 2

FROM  dreamacro/clash:latest

LABEL maintainer "zyao89 <zyao89@gmail.com>"

COPY --from=builder /app/dist /ui

COPY files/config.yaml /root/.config/clash/config.yaml

WORKDIR /

VOLUME ["/root/.config/clash"]

EXPOSE 7890
EXPOSE 7891
EXPOSE 80

# ENTRYPOINT ["/clash"]
HEALTHCHECK --interval=5s --timeout=1s CMD ps | grep darkhttpd | grep -v grep || exit 1
