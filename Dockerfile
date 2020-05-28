FROM node:latest as builder

WORKDIR /app
RUN git clone https://github.com/Dreamacro/clash-dashboard.git .
RUN yarn && yarn run build

# step 2

FROM  dreamacro/clash:latest

LABEL maintainer "zyao89 <zyao89@gmail.com>"

RUN mkdir -p /preset-conf \
    && mkdir -p /root/.config/clash \
    && apk add --no-cache darkhttpd iptables net-tools curl vim

COPY --from=builder /app/dist /ui

COPY files/config.yaml /preset-conf/config.yaml

COPY files/start.sh /start.sh
RUN chmod +x /start.sh

VOLUME ["/root/.config/clash"]

WORKDIR /
EXPOSE 7890
EXPOSE 7891
EXPOSE 9090
EXPOSE 80

ENTRYPOINT []

CMD ["/start.sh"]
HEALTHCHECK --interval=5s --timeout=1s CMD ps | grep darkhttpd | grep -v grep || exit 1
