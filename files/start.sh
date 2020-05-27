#!/bin/sh
set -e

PUID=${PUID:=0}
PGID=${PGID:=0}

if [ ! -f /root/.config/clash/config.yaml ]; then
    cp /preset-conf/config.yaml /root/.config/clash/config.yaml
    chown $PUID:$PGID /root/.config/clash/config.yaml
fi

chown $PUID:$PGID /root/.config/clash || echo 'Failed to set owner of /root/.config/clash'

darkhttpd /ui --port 80 &

exec /clash
