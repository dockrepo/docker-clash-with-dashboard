#!/bin/sh
set -e

PUID=${PUID:=0}
PGID=${PGID:=0}

# proxy
TRANSPARENT_PROXY=${TRANSPARENT_PROXY:=false}
REDIR_PORT=${REDIR_PORT:=7892}

if [ ! -f /root/.config/clash/config.yaml ]; then
    cp /preset-conf/config.yaml /root/.config/clash/config.yaml
    chown $PUID:$PGID /root/.config/clash/config.yaml
fi

if [ $TRANSPARENT_PROXY = 'true' ]; then
    echo "open TRANSPARENT_PROXY"
    
    reset_iptables(){
        iptables -P INPUT ACCEPT
        iptables -P FORWARD ACCEPT
        iptables -P OUTPUT ACCEPT
        iptables -t nat -F
        iptables -t mangle -F
        iptables -F
        iptables -X
    }
    
    set_clash_iptables(){
        # 在 nat 表中创建新链
        iptables -t nat -N CLASHRULE
        
        # iptables -t nat -A CLASHRULE -p tcp --dport 1905 -j RETURN
        
        iptables -t nat -A CLASHRULE -d 0.0.0.0/8 -j RETURN
        iptables -t nat -A CLASHRULE -d 10.0.0.0/8 -j RETURN
        iptables -t nat -A CLASHRULE -d 127.0.0.0/8 -j RETURN
        iptables -t nat -A CLASHRULE -d 169.254.0.0/16 -j RETURN
        iptables -t nat -A CLASHRULE -d 172.16.0.0/12 -j RETURN
        iptables -t nat -A CLASHRULE -d 192.168.0.0/16 -j RETURN
        iptables -t nat -A CLASHRULE -d 224.0.0.0/4 -j RETURN
        iptables -t nat -A CLASHRULE -d 240.0.0.0/4 -j RETURN
        iptables -t nat -A CLASHRULE -p tcp -j REDIRECT --to-ports $REDIR_PORT
        
        #拦截 dns 请求并且转发!
        # iptables -t nat -A PREROUTING -p udp --dport 53 -j REDIRECT --to-ports 53
        # iptables -t nat -A PREROUTING -p tcp --dport 53 -j REDIRECT --to-ports 53
        
        # 在 PREROUTING 链前插入 CLASHRULE 链,使其生效
        iptables -t nat -A PREROUTING -p tcp -j CLASHRULE
    }
    
    reset_iptables
    set_clash_iptables
    
    #开启转发
    echo "1" > /proc/sys/net/ipv4/ip_forward
    
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
