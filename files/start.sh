#!/bin/sh
set -e

PUID=${PUID:=0}
PGID=${PGID:=0}

# proxy
TRANSPARENT_PROXY=${TRANSPARENT_PROXY:='false'}
REDIR_PORT=${REDIR_PORT:=7892}

if [ ! -f /root/.config/clash/config.yaml ]; then
    cp /preset-conf/config.yaml /root/.config/clash/config.yaml
    chown $PUID:$PGID /root/.config/clash/config.yaml
fi

if [ $TRANSPARENT_PROXY = 'true' ]; then
    iptables -t nat -N Clash
    iptables -t nat -A Clash -p tcp -j REDIRECT --to-ports $REDIR_PORT
    iptables -t nat -A PREROUTING -p tcp -j Clash
    iptables -t nat -A PREROUTING -p tcp -j REDIRECT --to-ports $REDIR_PORT
    
    if [ -f /root/.config/clash/config.yaml ]; then
        if [ -z "`grep "redir-port" /root/.config/clash/config.yaml`" ]; then
            sed -i '$a redir-port: '${REDIR_PORT} /root/.config/clash/config.yaml
        else
            sed -i "s@redir-port.*@redir-port: $REDIR_PORT@g" /root/.config/clash/config.yaml
        fi
    fi
fi

chown $PUID:$PGID /root/.config/clash || echo 'Failed to set owner of /root/.config/clash'

darkhttpd /ui --port 80 &

exec /clash
