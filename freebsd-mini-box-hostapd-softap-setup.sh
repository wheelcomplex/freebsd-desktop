#
#
#

/sbin/ifaceboot wlan0 ath0 wlanmode hostap up

/sbin/ifaceboot bridge0 addm em1 addm em2 addm em3 addm wlan0 inet 172.236.150.43/24

#

# start on boot
cat <<'EOF' >> /etc/rc.local
# fix network interface configure in rc.conf
/sbin/ifaceboot wlan0 ath0 wlanmode hostap up
#
/sbin/ifconfig wlan0 txpower 5
#

/sbin/ifaceboot bridge0 addm em1 addm em2 addm em3 addm wlan0 inet 172.236.150.43/24

#
EOF

# for ul80
cat <<'EOF' >> /etc/rc.local
#!/bin/sh

#
# fix network interface configure in rc.conf
/sbin/ifaceboot wlan0 ath0 wlanmode hostap up
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

# ath0: MAC/BBP RT3070 (rev 0x0201), RF RT3020 (MIMO 1T1R), address 10:6f:3f:2c:09:fb

#
# 03:00.0 Network controller: Qualcomm Atheros AR928X Wireless Network Adapter (PCI-Express) (rev 01)
# using AR9280

ifconfig wlan0 list caps

ifconfig wlan0 list caps | grep -i hostap

# 

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
# md5sum h8 from 136
ssid=f14b38s65d

# Country code (ISO/IEC 3166-1).
country_code=US

# Operation mode (a = IEEE 802.11a, b = IEEE 802.11b, g = IEEE 802.11g)
hw_mode=g
channel=3
wpa=2
wpa_key_mgmt=WPA-PSK
wpa_passphrase=13609009086
wpa_pairwise=CCMP
ctrl_interface=/var/run/hostapd
ctrl_interface_group=wheel
#
EOF

#

cat <<'EOF' >> /etc/syslog.conf
# hostapd server logging
!hostapd
*.*             /var/log/messages
#
EOF

service syslogd restart

# load xauth or you will failed

/sbin/kldload wlan_xauth 2>/dev/null

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
ext_if  = "re0"
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
ext_if  = "re0"
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

cat <<'EOF' >> /etc/rc.conf
#
### http://www.freebsd.org/doc/en_US.ISO8859-1/books/handbook/firewalls-pf.html
pf_enable="YES"                 # Set to YES to enable packet filter (pf)
pf_rules="/etc/pf.conf"         # rules definition file for pf
pf_program="/sbin/pfctl"        # where the pfctl program lives
pf_flags=""                     # additional flags for pfctl
pflog_enable="YES"              # Set to YES to enable packet filter logging
pflog_logfile="/var/log/pflog"  # where pflogd should store the logfile
#
EOF

#
# make pptp snat work
#
# https://forum.pfsense.org/index.php?topic=46172.0
#

#
# ipfw default to block, setup rules first
#

cat <<'EOF' > /etc/rc.pptp.ipfw
#!/bin/sh

# from: 
# http://www.cyberciti.biz/faq/howto-setup-freebsd-ipfw-firewall/
# https://www.howtoforge.com/setting_up_a_freebsd_wlan_access_point
# https://forum.pfsense.org/index.php?topic=46172.0
#
# ipfw work with pf for pptp/gre
#

kldload libalias
kldload ipfw_nat

date >> /root/ipfw.list
echo "ARGS: $@" >> /root/ipfw.list
ipfw list >> /root/ipfw.list
date >> /root/ipfw.list

ext_if="re0"
ext_vpn_if="ng0"

#
if [ -z "$SSH_CONNECTION" ]
    then
    ipfw -q -f flush
fi

# default open
ipfw add 10 allow all from any to any

#
ipfw nat 1 config if $ext_if same_ports reset unreg_only
ipfw nat 2 config if $ext_vpn_if same_ports reset unreg_only

ipfw add 1000 nat 1 gre from any to any

ipfw list

date >> /root/ipfw.list
ipfw list >> /root/ipfw.list
date >> /root/ipfw.list

#
EOF

chmod +x /etc/rc.pptp.ipfw

/etc/rc.pptp.ipfw start

cat <<'EOF' >> /etc/rc.conf
#
firewall_enable="YES"
firewall_script="/etc/rc.pptp.ipfw"
#
EOF


#

pkg install -y nginx

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

#
# pptp server + client by mpd5
#
# https://forums.freebsd.org/threads/freebsd-pptp-vpn-client-howto.37191/
# http://hwchiu.logdown.com/posts/211563-mpd5-on-freebsd-100
# https://dnaeon.github.io/installing-and-configuring-a-pptp-server-with-mpd5-on-freebsd/
#
# note: pppd no exist after FreeBSD 7.x
#
#

pkg install -y mpd5

mkdir -p /usr/local/etc/mpd5/scripts/

cat <<'EOF' > /usr/local/etc/mpd5/mpd.conf
#
startup:
    set user rhinofly mpdfor2016 admin
    # telnet mpd-server.example.org 5005
    set console self 127.0.0.1 5005
    set console open
    # chrome http://mpd-server.example.org:5006
    set web self 0.0.0.0 5006
    set web open

default:
    load pptpclient
    # load pptpserver

pptpserver:
    set ippool add pool1 192.168.88.50 192.168.88.99
    create bundle template B
    set iface enable proxy-arp
    set iface idle 1800
    set iface enable tcpmssfix
    set iface route 192.168.88.1
    set ipcp yes vjcomp
    set ipcp ranges 192.168.88.1/32 ippool pool1
    set ipcp dns 4.2.2.1
    set ipcp dns 4.2.2.2
    set ipcp nbns 192.168.88.1
    set bundle enable compression
    set ccp yes mppc
    set mppc yes e40
    set mppc yes e128
    set mppc yes stateless
    create link template L pptp
    set link fsm-timeout 5
    set link action bundle B
    set link enable multilink
    set link yes acfcomp protocomp
    set link no pap chap eap chap-msv2
    set link enable chap chap-msv2 eap
    set link accept chap-msv2 
    set link keep-alive 10 60
    set link mtu 1460
    # security
    set pptp self 27.12.32.17
    set link enable incoming
#

pptpclient:
    create bundle static B1
    set ipcp ranges 0.0.0.0/0 0.0.0.0/0

    set iface up-script /usr/local/etc/mpd5/scripts/ip.up
    set iface down-script /usr/local/etc/mpd5/scripts/ip.down

    set bundle enable compression
    set ccp yes mppc
    set mppc accept compress
    set mppc yes e40 e56 e128
    set mppc yes stateless
    
    create link static L1 pptp
    set link action bundle B1
    set link accept chap
    set link max-redial 0

    # security
    set auth authname "VPNUSER"
    set auth password VPNPASSWORD
    set pptp peer VPN.server.com

    set pptp disable windowing
    # start to dial-out
    open
#

EOF

# change vpn account info
# vi /usr/local/etc/mpd5/mpd.conf


#
# for pptp server
#

cat <<'EOF' >> /usr/local/etc/mpd5/mpd.secret
#
foo   password226foo 192.168.88.100
bar   password227bar *
#
EOF


#
# vpn routing
#


mkdir -p /usr/local/etc/mpd5/scripts/ip.up.d /usr/local/etc/mpd5/scripts/ip.down.d


cat <<'EOF' > /usr/local/etc/mpd5/scripts/mpd.subr
#!/bin/sh
#
export PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin
#
export LOGCONSOLE='NO'
if [ -z "$LOGTAG" ]
    then
    LOGTAG="$0"
fi
export LOGTAG
#
LOGGER="/usr/bin/logger -p user.notice -t mpd5.script"
#
# do not login
if [ -z "$USER" ]
    then
    LOGCONSOLE=''
fi
#
slog(){
    local msg="[$LOGTAG] $@"
    test "$LOGCONSOLE" = 'YES' && echo "`date` $0 $msg" >&2
    $LOGGER "$msg"
}

#
pipelog(){
    local oneline
    while IFS= read -r oneline
    do
        slog "$oneline"
    done
}
#
EOF

cat <<'EOF' > /usr/local/etc/mpd5/scripts/ip.up
#!/bin/bash
. /usr/local/etc/mpd5/scripts/mpd.subr
#
#LOGTAG="ip.up"
#
# ARGS: ng0 inet 10.10.0.8/32 10.10.0.1 -   107.191.53.94

# # slog "ARGS:"
# # slog "#1: $1"
# # slog "#2: $2"
# # slog "#3: $3" # local vpn ip
# # slog "#4: $4" # remote vpn ip
# # slog "#5: $5"
# # slog "#6: $6" # remote wanip
# # slog "#7: $7" 
# # slog "#8: $8"
# # slog "#9: $9"
# # slog "---"

## ARGS:
## #1: ng0
## #2: inet
## #3: 10.10.0.11/32
## #4: 10.10.0.1
## #5: -
## #6: 107.191.53.94
## #7: 
## #8: 
## #9: 
## ---

slog "mpd5 script up: $@"
exitcode=0
for script in `ls -A /usr/local/etc/mpd5/scripts/ip.up.d/* 2>/dev/null`
do
    test ! -x "$script" && slog "warning: $script not executable." && continue
    scriptname=`basename $script`
    LOGTAG="up $scriptname" $script $@ 2>&1 | LOGTAG="up $scriptname" pipelog
    subcode=${PIPESTATUS[0]}
    if [ $subcode -ne 0 ]
        then
        # exitcode=$subcode
        slog "warning: execute $script $@ failed."
    fi
done
exit $exitcode
#
EOF

cat <<'EOF' > /usr/local/etc/mpd5/scripts/ip.down
#!/bin/bash
. /usr/local/etc/mpd5/scripts/mpd.subr
#
#LOGTAG="ip.down"
#
slog "mpd5 script down: $@"
exitcode=0
for script in `ls -A /usr/local/etc/mpd5/scripts/ip.down.d/* 2>/dev/null`
do
    test ! -x "$script" && slog "warning: $script not executable." && continue
    scriptname=`basename $script`
    LOGTAG="down $scriptname" $script $@ 2>&1 | LOGTAG="down $scriptname" pipelog
    subcode=${PIPESTATUS[0]}
    if [ $subcode -ne 0 ]
        then
        # exitcode=$subcode
        slog "warning: execute $script $@ failed."
    fi
done
exit $exitcode
#
EOF

#

cat <<'EOF' > /usr/local/etc/mpd5/scripts/ip.up.d/00defaultroute
#!/bin/bash
. /usr/local/etc/mpd5/scripts/mpd.subr
#
#LOGTAG="pptp.up.defaultroute"
#
DEFAULTGATEWAY='/var/run/mpd.pptpclient.defaultgateway'
#
# default            10.236.157.1       UGS         re0
#
wangw=`netstat -nr | grep 'default' | grep -v 'ng[0-9]*' | head -n 1 | awk '{print $2}'`
if [ -z "$wangw" ]
    then
    slog "warning: probe system default gateway failed."
    exit 1
fi
#
REMOTE="$6"
LOCAL="`echo "$3" | awk -F'/' '{print $1}'`"
slog "setup vpn default route: system $wangw, vpn $LOCAL, local $3, remote $REMOTE($4)"
echo $wangw > $DEFAULTGATEWAY
if [ $? -ne 0 ]
    then
    slog "warning: save system default gateway to $DEFAULTGATEWAY failed."
    exit 1
fi
route delete default
route delete $4 2>/dev/null
route add $REMOTE $wangw
route add default $LOCAL
#
EOF

cat <<'EOF' > /usr/local/etc/mpd5/scripts/ip.down.d/99defaultroute
#!/bin/bash
. /usr/local/etc/mpd5/scripts/mpd.subr
#
#LOGTAG="pptp.down.defaultroute"

DEFAULTGATEWAY='/var/run/mpd.pptpclient.defaultgateway'
#
pptpgw=`netstat -nr | grep 'default' | grep 'ng[0-9]*' | head -n 1 | awk '{print $2}'`
if [ -z "$pptpgw" ]
    then
    slog "warning: probe pptp default gateway failed."
    exit 1
fi
#
wangw=`cat $DEFAULTGATEWAY`
if [ -z "$wangw" ]
    then
    slog "warning: load system default gateway failed."
    exit 1
fi
REMOTE="$6"
LOCAL="`echo "$3" | awk -F'/' '{print $1}'`"
slog "restore system default route: system $wangw, vpn $pptpgw($REMOTE), local $3"
route delete $4
route delete default
route add default $wangw
rm -f $DEFAULTGATEWAY
#
EOF


#
# static route
#

cat <<'EOF'> /usr/local/etc/mpd5/static.routes
#
# dest-route route-to
#
# SYSGW = system default gateway
# VPNGW = vpn remote peer
#
remotename 10.0.0.0/8 SYSGW
#
EOF

#

cat <<'EOF' > /usr/local/etc/mpd5/scripts/ip.up.d/01staticroute
#!/bin/bash
. /usr/local/etc/mpd5/scripts/mpd.subr
#
#LOGTAG="pptp.up.staticroute"
#
STATICFILE='/usr/local/etc/mpd5/static.routes'
DEFAULTGATEWAY='/var/run/mpd.pptpclient.defaultgateway'
#
ACTIVEDFILE='/var/run/mpd.pptpclient.staticroute'
#
wangw=`netstat -nr | grep 'default' | grep -v 'ng[0-9]*' | head -n 1 | awk '{print $2}'`
if [ -z "$wangw" ]
    then
    wangw=`cat $DEFAULTGATEWAY`
    if [ -z "$wangw" ]
        then
            slog "warning: probe system default gateway failed."
        exit 1
    else
        slog "info: load system default gateway $wangw ok."
    fi
fi
#
test -s "$ACTIVEDFILE" && slog "warning: overwrite exist $ACTIVEDFILE" && cat $ACTIVEDFILE | pipelog && slog "---"
REMOTE="$6"
LOCAL="`echo "$3" | awk -F'/' '{print $1}'`"
slog "active static route: system $wangw, vpn $LOCAL, local $3, remote $REMOTE($4)"
#
echo '' > $ACTIVEDFILE
exitcode=0
while read line
do
    echo "$line" | grep -q '^#' && continue
    echo "$line" | grep -q '^$' && continue

    remotename=`echo "$line" | awk '{print $1}'`
    target=`echo "$line" | awk '{print $2}'`
    routedst=`echo "$line" | awk '{print $3}'`
    target="`echo $target|awk -F'/32' '{print $1}'`"
    if [ -z "$routedst" -o -z "$target" ]
        then
        slog "warning: invalid static route: $line"
        continue
    fi
    case $routedst in
        SYSGW)
        routedst="$wangw"
    ;;
    VPNGW)
        routedst="$LOCAL"
    ;;
    esac
    routetype='-host'
    echo "$target"| grep -q '/'
    test $? -eq 0 && routetype='-net'
    route -n show $target 2>/dev/null | grep -q "route to: $routedst"
    if [ $? -eq 0 ]
        then
        slog "warning: static route: $routetype $target $routedst($line) already exist."
        route -n show $target 2>&1 | pipelog
        continue
    fi
    route add $routetype $target $routedst
    if [ $? -ne 0 ]
        then
        slog "warning: add static route: $routetype $target $routedst($line) failed."
        exitcode=1
    else
        slog "info: add static route: $routetype $target $routedst($line) ok."
        echo "$remotename $target $routedst # $line" >> $ACTIVEDFILE
    fi
done < $STATICFILE
#
exit $exitcode
#
EOF

cat <<'EOF' > /usr/local/etc/mpd5/scripts/ip.down.d/90staticroute
#!/bin/bash
. /usr/local/etc/mpd5/scripts/mpd.subr
#
#LOGTAG="pptp.down.staticroute"
#
ACTIVEDFILE='/var/run/mpd.pptpclient.staticroute'
#
DEFAULTGATEWAY='/var/run/mpd.pptpclient.defaultgateway'
#
wangw=`cat $DEFAULTGATEWAY`
if [ -z "$wangw" ]
    then
    slog "warning: load system default gateway failed."
    exit 1
fi
#
REMOTE="$6"
LOCAL="`echo "$3" | awk -F'/' '{print $1}'`"
slog "deactive static route: system $wangw, vpn $LOCAL, local $3, remote $REMOTE($4)"
#
exitcode=0
while read line
do
    echo "$line" | grep -q '^#' && continue
    echo "$line" | grep -q '^$' && continue

    remotename=`echo "$line" | awk '{print $1}'`
    target=`echo "$line" | awk '{print $2}'`
    routedst=`echo "$line" | awk '{print $3}'`
    target="`echo $target|awk -F'/32' '{print $1}'`"
    if [ -z "$routedst" -o -z "$target" ]
        then
        slog "warning: invalid static route: $line"
        continue
    fi
    case $routedst in
        SYSGW)
        routedst="$wangw"
    ;;
    VPNGW)
        routedst="$LOCAL"
    ;;
    esac
    routetype='-host'
    echo "$target"| grep -q '/'
    test $? -eq 0 && routetype='-net'
    route -n show $target | grep -q "gateway: $routedst"
    if [ $? -ne 0 ]
        then
        slog "warning: static route: $routetype $target $routedst($line) not exist."
        #route -n show $target 2>&1 | pipelog
        continue
    fi
    route del $routetype $target $routedst
    if [ $? -ne 0 ]
        then
        slog "warning: delete static route: $routetype $target $routedst($line) failed."
        route del $routetype $target $routedst
        exitcode=1
    else
        slog "info: delete static route: $routetype $target $routedst($line) ok."
    fi
done < $ACTIVEDFILE
#
rm -f $ACTIVEDFILE
#
exit $exitcode
#
EOF


# security
chown -R root:wheel /usr/local/etc/mpd5
chmod -R 0600 /usr/local/etc/mpd5/*

chmod -R 0755 /usr/local/etc/mpd5/scripts/

chmod 0700 /usr/local/etc/mpd5

ls -alhR /usr/local/etc/mpd5/

cat <<'EOF' >> /etc/syslog.conf
# mpd server logging
!mpd
*.*             /var/log/messages
#
EOF

/etc/rc.d/syslogd restart 

tail -f /var/log/messages &

/usr/local/sbin/mpd5 -p /var/run/mpd5.pid

/usr/local/etc/rc.d/mpd5 onestart

#
cat <<'EOF' >> /etc/rc.conf
# enable mpd pptp server/client
mpd_enable="YES"
mpd_flags="-b"
#
gateway_enable="YES"
#
EOF

#

