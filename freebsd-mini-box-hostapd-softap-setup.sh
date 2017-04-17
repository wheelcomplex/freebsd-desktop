#
#
#

#
# dnsmasq dhcp server(with dns)
#

pkgloop install -y dnsmasq

#

cat <<'EOF'> /usr/local/etc/dnsmasq.conf
#
# port=0 to disable dns server part
#
port=53
#
no-resolv

server=8.8.8.8
server=8.8.4.4

# server=114.114.114.114
# server=8.8.8.8
# server=/google.com/8.8.8.8

# blacklist: baidu.com
address=/.baidu.com/127.0.0.1
address=/.baidustatic.com/127.0.0.1

# line 1 returns 198.51.100.100 for the host vpn.example.org.
# line 2 specifies 192.168.1.1 as the upstream DNS server for all other example.org queries such as admin.example.org.
# address=/vpn.example.org/198.51.100.100
# server=/example.org/192.168.1.1
server=/libs.baidu.com/8.8.8.8
server=/developer.baidu.com/8.8.8.8

all-servers

#
log-queries
#
# enable dhcp server
#
dhcp-range=172.16.0.91,172.16.0.110,2400h
#
#
log-dhcp
#
#
# no-dhcp-interface=em0
#
#dhcp-range=vmbr0,10.236.12.21,10.236.12.30,3h
# option 6, dns server
#dhcp-option=vmbr0,6,10.236.8.8
# option 3, default gateway
#dhcp-option=vmbr0,3,10.236.12.1
# option 15, domain-name
#dhcp-option=vmbr0,15,localdomain
# option 119, domain-search
#dhcp-option=vmbr0,119,localdomain
#
#dhcp-range=vmbr9,198.119.0.21,198.119.0.199,3h
# option 6, dns server
#dhcp-option=vmbr9,6,198.119.0.11
# option 3, default gateway
#dhcp-option=vmbr9,3,198.119.0.11
# option 15, domain-name
#dhcp-option=vmbr9,15,localdomain
# option 119, domain-search
#dhcp-option=vmbr9,119,localdomain
#
# dhcp options
#
#Nov  7 21:40:18 b2c-dc-pve1 dnsmasq-dhcp[8620]: 3744951815 DHCPOFFER(vmbr0) 10.236.12.180 36:b8:a4:ad:46:05 
#Nov  7 21:40:18 b2c-dc-pve1 dnsmasq-dhcp[8620]: 3744951815 requested options: 1:netmask, 28:broadcast, 2:time-offset, 3:router, 
#Nov  7 21:40:18 b2c-dc-pve1 dnsmasq-dhcp[8620]: 3744951815 requested options: 15:domain-name, 6:dns-server, 119:domain-search, 
#Nov  7 21:40:18 b2c-dc-pve1 dnsmasq-dhcp[8620]: 3744951815 requested options: 12:hostname, 44:netbios-ns, 47:netbios-scope, 
#Nov  7 21:40:18 b2c-dc-pve1 dnsmasq-dhcp[8620]: 3744951815 requested options: 26:mtu, 121:classless-static-route, 42:ntp-server
#Nov  7 21:40:18 b2c-dc-pve1 dnsmasq-dhcp[8620]: 3744951815 next server: 10.236.12.11
#Nov  7 21:40:18 b2c-dc-pve1 dnsmasq-dhcp[8620]: 3744951815 sent size:  1 option: 53 message-type  2
#Nov  7 21:40:18 b2c-dc-pve1 dnsmasq-dhcp[8620]: 3744951815 sent size:  4 option: 54 server-identifier  10.236.12.11
#Nov  7 21:40:18 b2c-dc-pve1 dnsmasq-dhcp[8620]: 3744951815 sent size:  4 option: 51 lease-time  10800
#Nov  7 21:40:18 b2c-dc-pve1 dnsmasq-dhcp[8620]: 3744951815 sent size:  4 option: 58 T1  5400
#Nov  7 21:40:18 b2c-dc-pve1 dnsmasq-dhcp[8620]: 3744951815 sent size:  4 option: 59 T2  9450
#Nov  7 21:40:18 b2c-dc-pve1 dnsmasq-dhcp[8620]: 3744951815 sent size:  4 option:  1 netmask  255.255.255.0
#Nov  7 21:40:18 b2c-dc-pve1 dnsmasq-dhcp[8620]: 3744951815 sent size:  4 option: 28 broadcast  10.236.12.255
#Nov  7 21:40:18 b2c-dc-pve1 dnsmasq-dhcp[8620]: 3744951815 sent size:  4 option:  3 router  10.236.12.11
#Nov  7 21:40:18 b2c-dc-pve1 dnsmasq-dhcp[8620]: 3744951815 sent size:  4 option:  6 dns-server  10.236.12.11
#
EOF

#

cat <<'EOF' >> /etc/syslog.conf
# dnsmasq server logging
!dnsmasq
*.*             /var/log/messages
!dnsmasq-dhcp
*.*             /var/log/messages
#
EOF

service syslogd restart

mv /etc/resolv.conf /etc/resolv.conf.orig.$$

cat <<'EOF'>/etc/resolv.conf
#
search localdomain
nameserver 127.0.0.1
#
EOF

chflags schg /etc/resolv.conf

# to unlock
# chflags noschg /etc/resolv.conf
# or
# chflags 0 /etc/resolv.conf

#

/usr/local/etc/rc.d/dnsmasq restart

sleep 1 && tail -n 20 /var/log/messages

#### ------------------------


## wpa2-psk wifi client
# for open wifi: ifconfig wlan0 ssid xxxx && dhclient wlan0

cp /etc/wpa_supplicant.conf /etc/wpa_supplicant.conf.dist.$$

cat <<'EOF' >/etc/wpa_supplicant.conf
#####wpa_supplicant configuration file ###############################
#
update_config=0

#
#ctrl_interface=/var/run/wpa_supplicant

#eapol_version=1

# ap_scan=1

# fast_reauth=1

# Simple case: WPA-PSK, PSK as an ASCII passphrase, allow all valid ciphers
network={
    #ssid="aluminium-136"
    #psk="13609009086"
    ssid="Xiaomi_0800"
    psk="meiyoumimaa"
    scan_ssid=1
    key_mgmt=WPA-PSK
    proto=RSN
    pairwise=CCMP TKIP
    group=CCMP TKIP
    priority=5
}
#
EOF

#
# debug
#

dmesg | grep -C 5 -i RF
dmesg | grep -C 5 -i Wireless

# for wifi client
/sbin/ifaceboot wlan1 run0 wlanmode sta up

# list ssid
ifconfig wlan1 scan;sleep 3;echo "----" && ifconfig wlan1 scan;

/usr/sbin/wpa_supplicant -d -i wlan1 -c /etc/wpa_supplicant.conf

# on boot startup
# check /etc/rc.local
#

#
# hostapd wifi ap
#
# https://www.freebsd.org/doc/handbook/network-wireless.html
#

pkg install -y hostapd pciutils usbutils

#

dmesg | grep -C 10 -i wlan

lspci && usbconfig list && lsusb

# rtwn0: MAC/BBP RT3070 (rev 0x0201), RF RT3020 (MIMO 1T1R), address 10:6f:3f:2c:09:fb

#
# 03:00.0 Network controller: Qualcomm Atheros AR928X Wireless Network Adapter (PCI-Express) (rev 01)
# using AR9280

ifconfig wlan0 list caps

ifconfig wlan0 list caps | grep -i hostap

# 
#

cat <<'EOF' >> /etc/syslog.conf
# hostapd server logging
!hostapd
*.*             /var/log/messages
#
EOF

service syslogd restart

# drivercaps=4f8def41<STA,FF,IBSS,PMGT,HOSTAP,AHDEMO,TXPMGT,SHSLOT,SHPREAMBLE,MONITOR,MBSS,WPA1,WPA2,BURST,WME,WDS,TXFRAG>
# cryptocaps=1f<WEP,TKIP,AES,AES_CCM,TKIPMIC>
# htcaps=701ce<CHWIDTH40,SHORTGI40,TXSTBC>
#
# you need HOSTAP + TKIP
#

# NOTE: TKIP is faster then CCMP

cat <<'EOF' > /etc/hostapd.conf
#
# https://w1.fi/cgit/hostap/plain/hostapd/hostapd.conf
#
interface=wlan0
driver=bsd
#
# SSID to be used in IEEE 802.11 management frames
ssid=tutux-136-mini

# Country code (ISO/IEC 3166-1).
country_code=US

# Operation mode (a = IEEE 802.11a, b = IEEE 802.11b, g = IEEE 802.11g)
hw_mode=g
channel=9
wpa=2
wpa_key_mgmt=WPA-PSK
wpa_passphrase=13609009086
# NOTE: TKIP is faster then CCMP
wpa_pairwise=TKIP CCMP
ctrl_interface=/var/run/hostapd
ctrl_interface_group=wheel
#
# Levels (minimum value for logged events):
#  0 = verbose debugging
#  1 = debugging
#  2 = informational messages
#  3 = notification
#  4 = warning
#
logger_syslog=0
logger_syslog_level=2
logger_stdout=-1
logger_stdout_level=2
#
EOF

# aarch64 autoload kmod disabled?
kmods="wlan wlan_xauth wlan_ccmp wlan_tkip wlan_acl wlan_amrr wlan_rssadapt"
for onemod in $kmods
do
    /sbin/kldload $onemod 2>/dev/null
done
kldstat|grep wlan

hostapd -d /etc/hostapd.conf

#

cat <<'EOF' >> /etc/rc.conf
#
hostapd_enable="YES"
#
gateway_enable="YES"
#
#
EOF

#

#
# SNAT firewall
#

cat <<'EOF' > /etc/pf.conf
#
# simple pf
#
#------------------------------------------------------------------------
# macros
#------------------------------------------------------------------------
#
# interfaces
ext_if  = "wlan1"
ext_vpn_if  = "ng0"
lan_if = "bridge0"

skipped_if = "{ lo }"

# Transparent Proxy
http_port = "80"
cache_host = "127.0.0.1"
cache_port = "9080"

dns_port = "53"
dnscache_host = "127.0.0.1"
dnscache_port = "53"

#------------------------------------------------------------------------
# options
#------------------------------------------------------------------------
# config
set block-policy return
set loginterface $ext_if
set loginterface $ext_vpn_if
set skip on $skipped_if
set state-policy if-bound

# scrub
scrub all reassemble tcp no-df
scrub in all fragment reassemble
scrub out all random-id

#------------------------------------------------------------------------
# redirection (and nat, too!)
#------------------------------------------------------------------------
# network address translation

# for pptp/gre
# no nat on $ext_if proto gre from any to any
# no nat on $ext_vpn_if proto gre from any to any

nat on $ext_if inet from ! ($ext_if) to any -> ($ext_if)
nat on $ext_vpn_if inet from ! ($ext_vpn_if) to any -> ($ext_vpn_if)

# redirect only IPv4 web traffic to squid 
#rdr pass on $lan_if inet proto tcp from any to any port $http_port -> $cache_host port $cache_port

# redirect dns traffic to local dnsmasq 
rdr pass on $lan_if inet proto tcp from any to any port $dns_port -> $dnscache_host port $dnscache_port

#------------------------------------------------------------------------
# firewall policy
#------------------------------------------------------------------------
# default pass
pass in quick from any to any
pass out quick from any to any
#
EOF

#

cat <<'EOF'> /usr/sbin/pfsess
#!/bin/sh
#
# check kmod of pf
#

kldload pf
kldload pflog

pfctl -e
# pf enabled

echo "/etc/pf.conf"
pfctl -vnf /etc/pf.conf

echo ""
errcode=0
if [ "$1" = "stop" -o "$1" = "start" ]
then
    pfctl -F nat && pfctl -F queue && pfctl -F rules
    errcode=$?
    sleep 1 
fi
if [ "$1" = "start" ]
then
    pfctl -f /etc/pf.conf
    errcode=$?
    sleep 1 
fi
#
echo "pf state"
pfctl -s rules && pfctl -s nat && pfctl -s state
#
exit $errcode
#
EOF

chmod +x /usr/sbin/pfsess

/usr/sbin/pfsess start

# pfctl -s all

#      -F modifier
#              Flush the filter parameters specified by modifier (may be
#              abbreviated):
# 
#              -F nat        Flush the NAT rules.
#              -F queue      Flush the queue rules.
#              -F rules      Flush the filter rules.
#              -F states     Flush the state table (NAT and filter).
#              -F Sources    Flush the source tracking table.
#              -F info       Flush the filter information (statistics that are
#                            not bound to rules).
#              -F Tables     Flush the tables.
#              -F osfp       Flush the passive operating system fingerprints.
#              -F all        Flush all of the above.
# 

# start on boot

test -f /etc/rc.local && mv /etc/rc.local /etc/rc.local.orig.$$

# NOTE: overwrite

cat <<'EOF' > /etc/rc.local
#!/bin/sh
LAN_ADDR="172.16.0.254/24"
# WAN_GW="172.16.0.254"
WANWIFI="run0"
LANWIFI="rtwn0"

LANCMD="/sbin/ifaceboot bridge0 addm ue0 addm ue1 addm re0 addm re1 addm am0 addm am1 addm wlan0 inet $LAN_ADDR"

service sshd start

# sleep to prevent panic
killall wpa_supplicant
sleep 1
killall hostapd
sleep 1
ifconfig wlan0 destroy
sleep 1
ifconfig wlan1 destroy
sleep 1
ifconfig bridge0 destroy
sleep 1
service netif stop
sleep 1
service netif start

#
if [ "$1" = "stop" ]
then
    $LANCMD
    test -n "$WAN_GW" && route add -net 0/0 $WAN_GW
    ifconfig
    netstat -nr
    exit 0
fi

# fix network interface configure in rc.conf
test -n "$LANWIFI" && /sbin/ifaceboot wlan0 $LANWIFI wlanmode hostap up && sleep 1
test -n "$WANWIFI" && /sbin/ifaceboot wlan1 $WANWIFI wlanmode sta up && sleep 1
#
test -n "$LANWIFI" && /sbin/ifconfig wlan0 txpower 30
test -n "$WANWIFI" && /sbin/ifconfig wlan1 txpower 30
#
test -n "$LANWIFI" && /sbin/ifconfig wlan0 up 
test -n "$WANWIFI" && /sbin/ifconfig wlan1 up 
#
$LANCMD
test -n "$WAN_GW" && route add -net 0/0 $WAN_GW && exit 0

# load xauth or you will failed

kmods="wlan wlan_xauth wlan_ccmp wlan_tkip wlan_acl wlan_amrr wlan_rssadapt"
for onemod in $kmods
do
    /sbin/kldload $onemod 2>/dev/null
done
kldstat|grep wlan

sleep 5
killall hostapd
sleep 1
rm -f /var/run/hostapd/wlan0
sleep 1
# /etc/rc.d/hostapd onestart
nohup /usr/sbin/hostapd -P /var/run/hostapd.pid -d /etc/hostapd.conf > /var/log/hostapd.log 2>&1 </dev/zero &
#
sleep 5
test -n "$LANWIFI" && /sbin/ifconfig wlan0 up 
test -n "$LANWIFI" && /sbin/ifconfig wlan0
#

/usr/sbin/wpa_supplicant -B -i wlan1 -c /etc/wpa_supplicant.conf
echo ""
echo "waiting for wlan1 ..."
for aaa in `seq 1 90`
do
    ifconfig wlan1 | grep -q 'status: associated'
    test $? -eq 0 && echo "connected" && break
    sleep 1
done
ifconfig wlan1
dhclient wlan1
ifconfig wlan1
#
#netstat -nr | grep bridge
#
/usr/sbin/pfsess start > /dev/null
#
EOF

chmod +x /etc/rc.local

#

# for proxy and cache
fastpkg install -y nginx

mkdir -p /home/appdata/nginx/htdocs/ /var/log/nginx /usr/local/etc/nginx/conf.d/

test ! -f /home/appdata/nginx/htdocs/robots.txt && cat <<'EOF'>/home/appdata/nginx/htdocs/robots.txt
Disallow: /
EOF

# using www

###

mkdir -p /home/appdata/nginx/htdocs/localfiles /home/appdata/nginx/cache /home/appdata/nginx/var/body /home/appdata/nginx/var/proxy /var/log/nginx

cat <<'EOF' > /home/appdata/nginx/htdocs/localfiles/index.html
<CENTER><h1>nginx local files</h1></CENTER>
EOF

chown -R root /home/appdata/nginx/

chmod -R 0755 /home/appdata/nginx/

chown -R www:www /home/appdata/nginx/cache

cat <<'EOF'>/usr/local/etc/nginx/nginx.conf
#
#
user www;
worker_processes  8;
worker_rlimit_nofile 65535;
# daemon on;
#error_log /var/log/nginx/error.log info;
error_log /var/log/nginx/error.log notice;
pid         /var/run/nginx.pid;
events {
    use kqueue;
    worker_connections  8192;
}
http {
    #
    include       mime.types;
    default_type  application/octet-stream;
    log_format main '"$server_addr"\t"$host"\t"$remote_addr"\t"$time_local"\t"$request_method $scheme://$host$request_uri"\t"$status"\t"$request_length"\t"$bytes_sent"\t"$request_time"\t"$sent_http_NGProxy_Cache_Status"\t"$upstream_addr"\t"$upstream_response_time"\t"$http_referer"\t"$http_user_agent"';
    access_log /var/log/nginx/access.log main;
    sendfile        on;
    server_tokens off;
    keepalive_timeout  65;
    client_header_timeout 30s;
    client_max_body_size 0;
    # disable proxy_buffering for netease music
    # NOTE: proxy_buffering off will disable proxy_cache !!!
    proxy_buffering on;
    # proxy_max_temp_file_size 20m;
    # proxy_buffer_size  2560k;
    # proxy_buffers   128 32k;
    # proxy_busy_buffers_size 2560k;
    server_names_hash_bucket_size 256;
    proxy_headers_hash_bucket_size 512;
    proxy_headers_hash_max_size 8192;
    proxy_connect_timeout    60;
    proxy_read_timeout       1200;
    proxy_send_timeout       1200;
    gzip  on;
    gzip_min_length    1024;
    gzip_proxied       expired no-cache no-store private auth no_last_modified no_etag;
    gzip_types         application/json application/x-json text/css text/xml text/plain application/xml;
    gzip_disable       "MSIE [1-6]\.";
    proxy_cache_path /home/appdata/nginx/cache levels=1:2 keys_zone=autocache:512m inactive=1d max_size=2g use_temp_path=off;
    #
    server {
        #
        #server for nginx cache
        #
        # resolver 114.114.114.114 valid=30s ipv6=off;
        # resolver 10.236.8.8 valid=30s ipv6=off;
        resolver 127.0.0.1 valid=30s ipv6=off;
        resolver_timeout 15s;
        #
        # listen 0.0.0.0:80;
        listen 0.0.0.0:9080;
        server_name  _;
        root /home/appdata/nginx/htdocs/;
        index index.html index.htm;
        log_not_found on;

        add_header  X-Info-Client-Ip $remote_addr always;
        add_header  X-Info-Host $host always;
        add_header  X-Info-Http-Host $http_host always;
        add_header  X-Info-Server-Ip $server_addr always;
        add_header  X-Info-Server-Port $server_port always;
        add_header  X-Info-Uri $request_uri always;

        set $islocal "";

        if ($http_host = "${server_addr}") {
          set $islocal "IP-";
        }

        if ($server_port = "80") {
          set $islocal "${islocal}80";
        }

        if ($http_host = "${server_addr}:${server_port}") {
          set $islocal "IP";
        }

        if ($http_host = "localhost:${server_port}") {
          set $islocal "IP";
        }

        if ($http_host = "localhost") {
          set $islocal "IP";
        }

        # 

        if ($request_uri ~ "^/localfiles(.*)") {
          set $islocal "localfiles";
        }

        if ($islocal = "IP") {
          return 302 $scheme://$http_host/localfiles$request_uri;
        }

        if ($islocal = "IP-80") {
          return 302 $scheme://$http_host/localfiles$request_uri;
        }

        location /localfiles {
                root /home/appdata/nginx/htdocs/;
                charset utf-8;
                autoindex on;
        }
        location = /stat/proxy.shtml {
            access_log  off;
            add_header  MiStat-Status STATINFO always;
            add_header Cache-Control  'private,max-age=0' always;
            expires epoch;
            add_header Content-Type "text/plain;charset=utf-8" always;
            return 200 "\r\nSTAT=OK;CODE=200;\r\nhostname=$hostname;\r\nhttp_host=$http_host;\r\nserver_addr=$server_addr;\r\nserver_port=$server_port;\r\nremote_addr=$remote_addr;\r\n\r\n";
        }
        proxy_intercept_errors off;
        reset_timedout_connection on;
        location / {
            proxy_http_version 1.1;
            proxy_set_header Host $host;
            proxy_pass http://$host$request_uri;
            # if ($request_method = POST ) {
            #     fastcgi_pass 127.0.0.1:1234;
            # }
            
            add_header  X-Info-Client-Ip $remote_addr always;
            add_header  X-Info-Host $host always;
            add_header  X-Info-Http-Host $http_host always;
            add_header  X-Info-Server-Ip $server_addr always;
            add_header  X-Info-Server-Port $server_port always;
            add_header  X-Info-Uri $request_uri always;

            client_body_temp_path /home/appdata/nginx/var/body 1 2;
            proxy_temp_path /home/appdata/nginx/var/proxy 1 2;
            proxy_cache autocache;
            proxy_cache_key $scheme$http_host$request_uri$is_args$args;
            # proxy_cache_valid 200 14d;
            proxy_cache_valid 200 120m;
            proxy_cache_valid 301 302 2m;
            proxy_cache_use_stale updating;
            proxy_cache_valid 404 10s;
            proxy_no_cache $http_range $http_if_range;
            proxy_no_cache $cookie_nocache $arg_nocache;
            proxy_no_cache $http_set_cookie;
            proxy_cache_bypass $http_range $http_if_range;
            proxy_cache_bypass $cookie_nocache $arg_nocache;
            proxy_cache_bypass $http_set_cookie;
            proxy_cache_bypass $http_pragma $http_authorization;
            proxy_cache_bypass $http_mixr_purge;
            #
            #
            #http://forum.nginx.org/read.php?2,214292,214293#msg-214293
            #http://wiki.nginx.org/HttpHeadersModule
            #MISS
            #EXPIRED - expired, request was passed to backend
            #UPDATING - expired, stale response was used due to proxy/fastcgi_cache_use_stale updating
            #STALE - expired, stale response was used due to proxy/fastcgi_cache_use_stale
            #HIT
            #
            add_header NGProxy-Cache-Status $upstream_cache_status always;
            #
            add_header NGProxy-Status AUTOPROXY always;
        }
    }
}
#
EOF


/usr/local/etc/rc.d/nginx restart;sleep 1;/usr/local/etc/rc.d/nginx status


cat <<'EOF' >> /etc/rc.conf
#
nginx_enable="YES"
#
EOF

/usr/local/etc/rc.d/nginx restart;sleep 1;/usr/local/etc/rc.d/nginx status

tail -f /var/log/nginx/access.log /var/log/nginx/error.log &

# truncate -s 4G /home/appdata/nginx/htdocs/x4.iso

http_proxy='' wget -S http://localhost/localfiles/ -O -

http_proxy='' wget -S http://localhost/ -O -

http_proxy='' wget -S http://127.0.0.1/ -O -

http_proxy='http://127.0.0.1:9080' wget -S --max-redirect=0 http://github.com/ -O -

http_proxy='http://127.0.0.1:9080' wget -S --max-redirect=0 'http://www.teara.govt.nz/files/p-24452-atl.jpg' -O /dev/null 2>&1 

#
