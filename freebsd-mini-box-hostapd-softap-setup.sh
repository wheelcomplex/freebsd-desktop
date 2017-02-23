#
#
#

/sbin/ifaceboot wlan0 rtwn0 wlanmode hostap up

/sbin/ifaceboot bridge0 addm re0 addm wlan0 inet 172.16.0.1/24

#

# start on boot
cat <<'EOF' >> /etc/rc.local
# fix network interface configure in rc.conf
/sbin/ifaceboot wlan0 rtwn0 wlanmode hostap up
#
/sbin/ifconfig wlan0 txpower 30
#

/sbin/ifaceboot bridge0 addm re0 addm wlan0 inet 172.236.0.1/24

#
EOF

# for ul80
cat <<'EOF' >> /etc/rc.local
#!/bin/sh

#
# wlanmode hostap for softap, sta for wifi client

/sbin/ifaceboot wlan0 rtwn0 wlanmode hostap up
#
/sbin/ifconfig wlan0 txpower 5
#

/sbin/ifaceboot bridge0 addm re0 addm wlan0 ether 90:e6:ba:2b:e7:7f inet DHCP

#
EOF

# check base setup for dnsmasq installation

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

# load xauth or you will failed

/sbin/kldload wlan_xauth

# drivercaps=4f8def41<STA,FF,IBSS,PMGT,HOSTAP,AHDEMO,TXPMGT,SHSLOT,SHPREAMBLE,MONITOR,MBSS,WPA1,WPA2,BURST,WME,WDS,TXFRAG>
# cryptocaps=1f<WEP,TKIP,AES,AES_CCM,TKIPMIC>
# htcaps=701ce<CHWIDTH40,SHORTGI40,TXSTBC>
#
# you need HOSTAP + TKIP
#

cat <<'EOF' > /etc/hostapd.conf
#
# https://w1.fi/cgit/hostap/plain/hostapd/hostapd.conf
#
interface=wlan0
driver=bsd
#
# SSID to be used in IEEE 802.11 management frames
ssid=ntank-136

# Country code (ISO/IEC 3166-1).
country_code=US

# Operation mode (a = IEEE 802.11a, b = IEEE 802.11b, g = IEEE 802.11g)
hw_mode=g
channel=9
wpa=2
wpa_key_mgmt=WPA-PSK
wpa_passphrase=13609009086
wpa_pairwise=CCMP
ctrl_interface=/var/run/hostapd
ctrl_interface_group=wheel
#
EOF

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

# start on boot
cat <<'EOF' >> /etc/rc.local
#
# load xauth or you will failed

/sbin/kldload wlan_xauth 2>/dev/null
/sbin/kldload wlan_ccmp 2>/dev/null
/sbin/kldload wlan_tkip 2>/dev/null

/etc/rc.d/hostapd stop
sleep 5
/etc/rc.d/hostapd start

#
EOF

#
# SNAT firewall
#

#

cat <<'EOF' > /etc/pf.conf
#

# from: 
# http://www.cyberciti.biz/faq/howto-setup-freebsd-ipfw-firewall/
# https://www.howtoforge.com/setting_up_a_freebsd_wlan_access_point
# https://forum.pfsense.org/index.php?topic=46172.0
#

#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
# This configuration is set for use on a machine that is a router with
# three (3) network cards:
# ext_if - connects to the upstream link (cable/dsl modem, WAN, etc.)
# wifi_if - wireless card for internal network
#           (if none present, remove all references to it in this file)
# lan_if  - wired card for internal network
#           (if none present, remove all references to it in this file)
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#------------------------------------------------------------------------
# macros
#------------------------------------------------------------------------
logopt = "log"
# interfaces
ext_if  = "wlan1"
ext_vpn_if  = "ng0"
wifi_if = "wlan0"
lan_if  = "bridge0"
# publically accesible services (transport layer neutral)
pubserv = "{ 22, 443, 80, 8090 }"
# internally accessible services (transport layer neutral)
lanserv = "{ 22, 53, 67, 80, 443, 8090 }"
# samba ports (transport layer neutral)
samba_ports = "{ 137, 138, 139, 445 }"
# externally permitted inbound icmp types
icmp_types = "echoreq"
# internal network
lan_net = "{ 172.236.150.0/24 }"
# hosts granted acces to samba (cifs/smb) shares
smb_net = "{ 172.236.150.0/27, 10.0.0.0/8 }"
# block these networks
# table = "{ 0.0.0.0/8, 10.0.0.0/8, 20.20.20.0/24, 127.0.0.0/8, \
#         169.254.0.0/16, 172.16.0.0/12,  192.0.2.0/24, 172.236.150.0/16, \
#         224.0.0.0/3,    255.255.255.255 }"
# table = "{ 127.0.0.99/32 }"
#------------------------------------------------------------------------
# options
#------------------------------------------------------------------------
# config
set block-policy return
set loginterface $ext_if
set loginterface $ext_vpn_if
set skip on lo0
# scrub
#scrub all reassemble tcp no-df
#scrub in all fragment reassemble
scrub out all random-id
#------------------------------------------------------------------------
# redirection (and nat, too!)
#------------------------------------------------------------------------
# network address translation
# for pptp/gre
no nat on $ext_if proto gre from any to any
nat on $ext_if from $lan_net to any -> ($ext_if)
no nat on $ext_vpn_if proto gre from any to any
nat on $ext_vpn_if from $lan_net to any -> ($ext_vpn_if)
#------------------------------------------------------------------------
# firewall policy
#------------------------------------------------------------------------
# restrictive default rules
block all
block return-rst  in  $logopt on $ext_if proto tcp all
block return-icmp in  $logopt on $ext_if proto udp all
block             in  $logopt on $ext_if proto icmp all
block             out $logopt on $ext_if all

block return-rst  in  $logopt on $ext_vpn_if proto tcp all
block return-icmp in  $logopt on $ext_vpn_if proto udp all
block             in  $logopt on $ext_vpn_if proto icmp all
block             out $logopt on $ext_vpn_if all

# trust localhost
pass in  quick on lo0 all
pass out quick on lo0 all
# anti spoofing

block drop in  $logopt quick on $ext_if from any to any
block drop out $logopt quick on $ext_if from any to any

block drop in  $logopt quick on $ext_vpn_if from any to any
block drop out $logopt quick on $ext_vpn_if from any to any
antispoof for { $lan_if, $wifi_if, $ext_if, $ext_vpn_if }

# anti fake return-scans
block  return-rst  out on $ext_if proto tcp all 
block  return-rst  in  on $ext_if proto tcp all 
block  return-icmp out on $ext_if proto udp all
block  return-icmp in  on $ext_if proto udp all 

block  return-rst  out on $ext_vpn_if proto tcp all 
block  return-rst  in  on $ext_vpn_if proto tcp all 
block  return-icmp out on $ext_vpn_if proto udp all
block  return-icmp in  on $ext_vpn_if proto udp all 

# toy with script kiddies scanning us
block in $logopt quick proto tcp flags FUP/WEUAPRSF 
block in $logopt quick proto tcp flags WEUAPRSF/WEUAPRSF 
block in $logopt quick proto tcp flags SRAFU/WEUAPRSF 
block in $logopt quick proto tcp flags /WEUAPRSF 
block in $logopt quick proto tcp flags SR/SR 
block in $logopt quick proto tcp flags SF/SF 
# open firewall fully
# warning: insecure. 'nuff said.
#pass in  quick all
#pass out quick all
# allow permitted icmp
pass in inet proto icmp all icmp-type $icmp_types keep state
# allow permitted services
pass in on $ext_if            inet proto tcp       from any      to any port $pubserv flags S/SA keep state

# pass in on $ext_vpn_if        inet proto tcp       from any      to any port $pubserv flags S/SA keep state

pass in quick on {$lan_if $wifi_if}                      from any to any                               keep state
# pass in on {$lan_if $wifi_if} inet proto {tcp udp} from $lan_net to any port $lanserv            keep state
# pass in on {$lan_if $wifi_if} inet proto {tcp udp} from $smb_net to any port $samba_ports        keep state
# permit access between LAN hosts
pass in  from $lan_net to $lan_net keep state
pass out from $lan_net to $lan_net keep state
# permit full outbound access 
# warning: potentially insecure. you may wish to lock down outbound access.
pass out from any to any keep state
#
EOF

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

echo '/usr/sbin/pfsess start' >> /etc/rc.local

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

cat <<'EOF'>/etc/rc.local
#!/bin/sh
killall wpa_supplicant
sleep 1
killall hostapd
sleep 1
ifconfig wlan0 destroy
sleep 1
ifconfig wlan1 destroy
sleep 1
ifconfig bridge0 destroy
#
# fix network interface configure in rc.conf
/sbin/ifaceboot wlan0 run0 wlanmode hostap up
sleep 1
/sbin/ifaceboot wlan1 rtwn0 wlanmode sta up
sleep 1
#
/sbin/ifconfig wlan0 txpower 30
/sbin/ifconfig wlan1 txpower 30
#
/sbin/ifconfig wlan0 up 
/sbin/ifconfig wlan1 up 
#
/sbin/ifaceboot bridge0 addm re0 addm wlan0 inet 172.16.0.1/24

# load xauth or you will failed
/sbin/kldload wlan_xauth 2>/dev/null
/sbin/kldload wlan_ccmp 2>/dev/null
/sbin/kldload wlan_tkip 2>/dev/null

sleep 5
rm -f /var/run/hostapd/wlan0
/etc/rc.d/hostapd onestart
#

#route add -net 0/0 192.168.31.1

/usr/sbin/wpa_supplicant -B -i wlan1 -c /etc/wpa_supplicant.conf
echo ""
echo "waiting for wlan1 ..."
for aaa in `seq 1 90`
do
    ifconfig wlan1 | grep -q 'status: associated'
    test $? -eq 0 && echo "connected" && ifconfig wlan1 && break
    sleep 1
done
dhclient wlan1
#
#netstat -nr | grep bridge
#
/usr/sbin/pfsess start > /dev/null
#
EOF

#

pkg install -y nginx

mkdir -p /usr/share/nginx/html/ /var/log/ /usr/local/etc/nginx/conf.d/

cat <<'EOF'>/usr/share/nginx/html/robots.txt
Disallow: /
EOF

# using www

cat <<'EOF' > /usr/local/etc/nginx/nginx.conf 
#
user  www;
worker_processes  2;

error_log  /var/log/nginx/error.log notice;
pid        /var/run/nginx.pid;

events {
    worker_connections  1024;
}

http {
    include       /usr/local/etc/nginx/mime.types;
    default_type  application/octet-stream;

    log_format  main  '$remote_addr - $remote_user [$time_local] "$scheme://$http_host$request_uri" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';

    access_log  /var/log/nginx/access.log  main;

    sendfile        on;
    #tcp_nopush     on;

    keepalive_timeout  65;

    #gzip  on;

    include /usr/local/etc/nginx/conf.d/*.conf;
}
EOF

cat <<'EOF'> /usr/local/etc/nginx/conf.d/default.conf
# server {
#         # http2 server
#         listen 443 ssl http2 default_server;
#         listen [::]:443 ssl http2 default_server;
#         server_name _;
#         ssl_certificate /etc/letsencrypt/live/horde.today/fullchain.pem;
#         ssl_certificate_key /etc/letsencrypt/live/horde.today/privkey.pem;
#         ssl_ciphers EECDH+CHACHA20:EECDH+AES128:RSA+AES128:EECDH+AES256:RSA+AES256:EECDH+3DES:RSA+3DES:!MD5;
#         ssl_dhparam  /usr/local/etc/nginx/ssl/dhparam.pem;
#         ssl_session_cache shared:SSL:5m;
#         ssl_session_timeout 1h;
# 
#         charset utf-8;
# 
#         access_log  /var/log/nginx/ssl.access.log  main;
# 
#         add_header Strict-Transport-Security "max-age=15768000; includeSubDomains: always;";
# 
#        location / {
#            root   /usr/share/nginx/html;
#            index  index.html index.htm;
#        }
# 
#         # redirect server error pages to the static page /50x.html
#         #
#         error_page   500 502 503 504  /50x.html;
#         location = /50x.html {
#             root   /usr/share/nginx/html;
#         }
# 
#         # proxy the PHP scripts to Apache listening on 127.0.0.1:80
#         #
#         #location ~ \.php$ {
#         #    proxy_pass   http://127.0.0.1;
#         #}
# 
#         # pass the PHP scripts to FastCGI server listening on 127.0.0.1:9000
#         #
#         #location ~ \.php$ {
#         #    root           html;
#         #    fastcgi_pass   127.0.0.1:9000;
#         #    fastcgi_index  index.php;
#         #    fastcgi_param  SCRIPT_FILENAME  /scripts$fastcgi_script_name;
#         #    include        fastcgi_params;
#         #}
# 
#         # deny access to .htaccess files, if Apache's document root
#         # concurs with nginx's one
#         #
#         #location ~ /\.ht {
#         #    deny  all;
#         #}
# }
# 
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    server_name _;
    
        access_log  /var/log/nginx/http.access.log  main;

        location / {
            # uncomment return 301 after letencrypto setup ok
            # should be http_host instead of server_name.
            # return 301 https://$http_host$request_uri;
            root /usr/share/nginx/html;
            # index  index.html index.htm;
        }
        # for letsencrypt
        location ~ /.well-known {
            root   /usr/share/nginx/html;
            allow all;
        }
}
EOF


###

mkdir -p /home/data/nginx/htdocs/localfiles /home/data/nginx/cache /home/data/nginx/var/body /home/data/nginx/var/proxy

cat <<'EOF' > /home/data/nginx/htdocs/localfiles/index.html
<CENTER><h1>nginx local files</h1></CENTER>
EOF

chown -R root /home/data/nginx/

chmod -R 0755 /home/data/nginx/

cat <<'EOF'>/usr/local/etc/nginx/nginx.conf
#
#
user www;
worker_processes  4;
worker_rlimit_nofile 6638400;
# daemon on;
#error_log /var/log/nginx-error.log info;
error_log /var/log/nginx-error.log notice;
pid         /var/run/nginx.pid;
events {
    use kqueue;
    worker_connections  16384;
}
http {
    #
    include       mime.types;
    default_type  application/octet-stream;
    log_format main '"$server_addr"\t"$host"\t"$remote_addr"\t"$time_local"\t"$request_method $scheme://$host$request_uri"\t"$status"\t"$request_length"\t"$bytes_sent"\t"$request_time"\t"$sent_http_MiXr_Cache_Status"\t"$upstream_addr"\t"$upstream_response_time"\t"$http_referer"\t"$http_user_agent"';
    access_log /var/log/nginx-access.log main;
    sendfile        on;
    server_tokens off;
    keepalive_timeout  65;
    client_header_timeout 30s;
    client_max_body_size 0;
    # disable proxy_buffering for netease music
    proxy_buffering off;
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
    proxy_cache_path /home/data/nginx/cache levels=1:2 keys_zone=autocache:128m inactive=1d max_size=2g;
    #
    server {
        #
        #server for nginx cache
        #
        #resolver 114.114.114.114 valid=30s ipv6=off;
        resolver 10.236.8.8 valid=30s ipv6=off;
        #resolver 127.0.0.1 valid=30s ipv6=off;
        resolver_timeout 15s;
        #
        listen 0.0.0.0:80;
        listen 0.0.0.0:9080;
        server_name  _;
        root /home/data/nginx/htdocs/;
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
                root /home/data/nginx/htdocs/;
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

            add_header  X-Info-Client-Ip $remote_addr always;
            add_header  X-Info-Host $host always;
            add_header  X-Info-Http-Host $http_host always;
            add_header  X-Info-Server-Ip $server_addr always;
            add_header  X-Info-Server-Port $server_port always;
            add_header  X-Info-Uri $request_uri always;

            client_body_temp_path /home/data/nginx/var/body 1 2;
            proxy_temp_path /home/data/nginx/var/proxy 1 2;
            proxy_cache autocache;
            proxy_cache_key $scheme$host$request_uri$is_args$args;
            proxy_cache_valid 200 14d;
            proxy_cache_valid 301 302 2m;
            proxy_cache_use_stale updating;
            proxy_cache_valid 404 10s;
            proxy_no_cache $http_range $http_if_range;
            proxy_cache_bypass $http_range $http_if_range;
            proxy_cache_bypass $cookie_nocache $arg_nocache;
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
            add_header MiXr-Cache-Status $upstream_cache_status always;
            #
            add_header MiXr-Status AUTOPROXY always;
            proxy_set_header Host $host;
            proxy_pass http://$host$request_uri;
        }
    }
}
#
EOF


cat <<'EOF' >> /etc/rc.conf
#
nginx_enable="YES"
#
EOF


/usr/local/etc/rc.d/nginx restart;sleep 1;/usr/local/etc/rc.d/nginx status

tail -f /var/log/nginx-access.log /var/log/nginx-error.log &

# dd if=/dev/zero of=/home/rhinofly/nginx-www/x.iso bs=1M count=4096

http_proxy='' wget -S http://localhost/localfiles/ -O -

http_proxy='' wget -S http://localhost/ -O -

http_proxy='' wget -S http://127.0.0.1/ -O -

http_proxy='http://127.0.0.1:9080' wget -S --max-redirect=0 http://github.com/ -O -

#
