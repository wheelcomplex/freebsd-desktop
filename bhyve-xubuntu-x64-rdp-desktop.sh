#
# https://agentoss.wordpress.com/2011/10/31/creating-a-wireless-access-point-with-debian-linux/
# http://www.christianix.de/linux-tutor/hostapd.html
# https://wireless.wiki.kernel.org/welcome

# for xubuntu x64 16.04

apt install -y curl vim geany

#
touch /etc/rc.local
chmod +x /etc/rc.local
#
sed -i -e '/exit 0/d' /etc/rc.local
sed -i -e 's/sh -e/sh/' /etc/rc.local
#

echo '#!/bin/bash' >/tmp/aaaa

cat /etc/rc.local >> /tmp/aaaa


# need #!/bin/bash at first line, otherwise rc-local.service fail to start
# https://bbs.archlinux.org/viewtopic.php?id=149425
cat /tmp/aaaa > /etc/rc.local

cat /etc/rc.local

# for 17.10
cat <<'EOF'> /etc/systemd/system/rc-local.service
# https://askubuntu.com/questions/886620/how-can-i-execute-command-on-startup-rc-local-alternative-on-ubuntu-16-10
[Unit]
Description=/etc/rc.local Compatibility
ConditionPathExists=/etc/rc.local

[Service]
Type=forking
ExecStart=/etc/rc.local start
TimeoutSec=0
StandardOutput=tty
RemainAfterExit=yes
SysVStartPriority=99

[Install]
WantedBy=multi-user.target

#
EOF

chmod +x /etc/rc.local

sudo systemctl enable rc-local

sudo systemctl start rc-local.service
sudo systemctl status rc-local.service

# nginx for local test

curl http://nginx.org/keys/nginx_signing.key | apt-key add -

cat <<'EOF' > /etc/apt/sources.list.d/nginx.list
# trusty for ubuntu 14.04, xenial for 16.04, zesty for 17.04
deb http://nginx.org/packages/ubuntu/ xenial nginx
# deb-src http://nginx.org/packages/ubuntu/ xenial nginx
#
EOF

# install nginx 1.10 (the stable version)
apt-get update;
apt-get install -y nginx

cat <<'EOF'>/usr/share/nginx/html/robots.txt
Disallow: /
EOF

# using www-data

mkdir -p /usr/share/nginx/html/.well-known

cat <<'EOF' > /etc/nginx/nginx.conf 
#
user  www-data;
worker_processes  2;

error_log  /var/log/nginx/error.log notice;
pid        /var/run/nginx.pid;

events {
    worker_connections  1024;
}

http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;

    log_format  main  '$remote_addr - $remote_user [$time_local] "$scheme://$http_host$request_uri" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';

    access_log  /var/log/nginx/access.log  main;

    sendfile        on;
    #tcp_nopush     on;

    keepalive_timeout  65;

    #gzip  on;

    include /etc/nginx/conf.d/*.conf;
}
EOF

cat <<'EOF'> /etc/nginx/conf.d/default.conf
# server {
#         # http2 server
#         listen 443 ssl http2 default_server;
#         listen [::]:443 ssl http2 default_server;
#         server_name _;
#         ssl_certificate /etc/letsencrypt/live/horde.today/fullchain.pem;
#         ssl_certificate_key /etc/letsencrypt/live/horde.today/privkey.pem;
#         ssl_ciphers EECDH+CHACHA20:EECDH+AES128:RSA+AES128:EECDH+AES256:RSA+AES256:EECDH+3DES:RSA+3DES:!MD5;
#         ssl_dhparam  /etc/nginx/ssl/dhparam.pem;
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
            # for letencrypt: /usr/share/nginx/html/.well-known
            root   /usr/share/nginx/html;
            allow all;
        }
}
EOF

nginx -t && service nginx restart

#

#
cat <<'EOF'> /usr/sbin/rmmod-recursive
#!/bin/bash
MOD="$1"

rmdeps(){
    local mod="$1"
    local mark="$2"
    test -z "$mod" && return 0
    local item=''
    echo "${mark}$mod"
    for item in `lsmod | grep "^$mod "|awk '{print $4}'|tr ',' ' '`
    do
        local deplist="`lsmod | grep "^$item "|awk '{print $4}'|tr ',' ' '`"
        local depitem=''
        for depitem in $deplist
        do
            rmdeps $depitem "${mark}-"
        done
        modprobe -r -v $item
    done
    modprobe -r -v $mod
    return 0
}

test -z "$MOD" && echo "USAGE: $0 <mod>" && exit 1

rmdeps $MOD

EOF

chmod +x /usr/sbin/rmmod-recursive

/usr/sbin/rmmod-recursive

apt-get install -y screen

VMNIC=`netstat -nr|grep ^0.0.0.0 | awk '{print $8}'`

echo $VMNIC

if [ -n "$VMNIC" ]
then
# note: use EOF for ${VMNIC}, do not use 'EOF'
cat <<EOF > /etc/network/interfaces
#
# networking with hostapd softap
#
# interfaces(5) file used by ifup(8) and ifdown(8)
auto lo
iface lo inet loopback

# wired link
auto ${VMNIC}
iface ${VMNIC} inet dhcp 
#
EOF

cat /etc/network/interfaces

# NOTE: /etc/network/interfaces does not works in ubuntu 17.10

# note: use EOF for ${VMNIC}, do not use 'EOF'
cat <<EOF >> /etc/rc.local
# wired link up
ifconfig ${VMNIC} up && dhclient ${VMNIC}
#
EOF

cat /etc/rc.local
else
    echo ""
    echo ""
    echo "WIRED NIC NOT FOUND!"
    echo ""
    echo ""
fi

# remove network-manager
apt-get remove -y network-manager

# RDP remote desktop
# http://c-nergy.be/blog/?p=10448
# https://www.interserver.net/tips/kb/install-xrdp-ubuntu-server-xfce-template/

# for every desktop user
# echo “xfce4-session” > ~/.xsession

sudo apt-get install -y xrdp

/etc/init.d/xrdp start

/etc/init.d/xrdp status

# boot to text console
sed -i -e '/GRUB_CMDLINE_LINUX_DEFAULT/d' /etc/default/grub
echo 'GRUB_CMDLINE_LINUX_DEFAULT="text"' >> /etc/default/grub

update-grub

sudo systemctl enable multi-user.target --force
sudo systemctl set-default multi-user.target

sudo systemctl disable lightdm

# 16.04 is ok, 17.10 show black screen when connect by rdesktop from FreeBSD

# nfs client/home
# https://www.digitalocean.com/community/tutorials/how-to-set-up-an-nfs-mount-on-ubuntu-16-04

apt-get update && apt-get install -y nfs-common

# list remote exports
showmount -e 172.16.254.254

## apps

apt-get install -y sysstat gitk gparted filezilla geany

# nodejs
# https://nodejs.org/en/download/package-manager/#debian-and-ubuntu-based-linux-distributions

# NOTE: bluemix is using 6.x
curl -sL https://deb.nodesource.com/setup_6.x | sudo -E bash -
sudo apt-get install -y nodejs

#
curl -sL https://deb.nodesource.com/setup_8.x | sudo -E bash -
sudo apt-get install -y nodejs

sudo apt-get install -y build-essential

sudo npm install -g nodemon express serve-favicon express-session
sudo npm install -g passport passport-local mongoose passport-local-mongoose 

# visual studio code
# https://code.visualstudio.com/docs/setup/linux

echo 'fs.inotify.max_user_watches=524288' >> /etc/sysctl.conf

curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg

sudo mv microsoft.gpg /etc/apt/trusted.gpg.d/microsoft.gpg

sudo sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main" > /etc/apt/sources.list.d/vscode.list'

sudo apt-get update && sudo apt-get install code

# program name = code
# run for normal user
xdg-mime default code.desktop text/plain

# run
sudo update-alternatives --set editor /usr/bin/code

# google chrome
# https://askubuntu.com/questions/510056/how-to-install-google-chrome
wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add -

echo 'deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main' | sudo tee /etc/apt/sources.list.d/google-chrome.list

apt-get update && apt-get install -y google-chrome-stable

# Cloud Foundry for bluemix
# https://console.bluemix.net/docs/cli/reference/bluemix_cli/get_started.html#getting-started

mkdir tmp && wget https://clis.ng.bluemix.net/download/bluemix-cli/latest/linux64 -O tmp/bluemixcli.tar.gz && cd tmp && tar xfz bluemixcli.tar.gz && \
cd Bluemix_CLI && sudo ./install_bluemix_cli
# bx is ready



