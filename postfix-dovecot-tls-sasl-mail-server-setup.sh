#
# in https://www.alpharacks.com/myrack/clientarea.php
# ubuntu
#
# https://www.digitalocean.com/community/tutorials/how-to-set-up-a-postfix-e-mail-server-with-dovecot
#

# using system user
# 
#

# DNS
#   
#   dig TXT example.com
#   
#   ; <<>> DiG 9.10.4-P2 <<>> TXT example.com
#   ;; global options: +cmd
#   ;; Got answer:
#   ;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 8971
#   ;; flags: qr rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1
#   
#   ;; OPT PSEUDOSECTION:
#   ; EDNS: version: 0, flags:; udp: 4000
#   ;; QUESTION SECTION:
#   ;example.com.        IN    TXT
#   
#   ;; ANSWER SECTION:
#   example.com.    300    IN    TXT    "v=spf1 +a:smtp.example.com +mx ~all"
#   
#   ;; Query time: 356 msec
#   ;; SERVER: 10.236.8.8#53(10.236.8.8)
#   ;; WHEN: Wed Aug 03 11:43:36 CST 2016
#   ;; MSG SIZE  rcvd: 100
#   
#   dig MX example.com
#   
#   ; <<>> DiG 9.10.4-P2 <<>> MX example.com
#   ;; global options: +cmd
#   ;; Got answer:
#   ;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 29380
#   ;; flags: qr rd ra; QUERY: 1, ANSWER: 6, AUTHORITY: 0, ADDITIONAL: 7
#   
#   ;; OPT PSEUDOSECTION:
#   ; EDNS: version: 0, flags:; udp: 4000
#   ;; QUESTION SECTION:
#   ;example.com.        IN    MX
#   
#   ;; ANSWER SECTION:
#   example.com.    299    IN    MX    20 mx2.example.com.
#   example.com.    299    IN    MX    30 mx3.example.com.
#   example.com.    299    IN    MX    10 mx1.example.com.
#   example.com.    299    IN    MX    50 mx5.example.com.
#   example.com.    299    IN    MX    40 mx4.example.com.
#   example.com.    299    IN    MX    60 mx6.example.com.
#   
#   ;; ADDITIONAL SECTION:
#   mx2.example.com.    299    IN    A    192.161.180.94
#   mx3.example.com.    299    IN    A    192.161.180.94
#   mx1.example.com.    298    IN    A    192.161.180.94
#   mx5.example.com.    298    IN    A    192.161.180.94
#   mx4.example.com.    297    IN    A    192.161.180.94
#   mx6.example.com.    297    IN    A    192.161.180.94
#   
#   ;; Query time: 3190 msec
#   ;; SERVER: 10.236.8.8#53(10.236.8.8)
#   ;; WHEN: Wed Aug 03 13:47:35 CST 2016
#   ;; MSG SIZE  rcvd: 262


cat <<'EOF' > /etc/hostname
mx1
EOF

cat <<'EOF' > /etc/hosts
ff02::1        ip6-allnodes
ff02::2        ip6-allrouters

127.0.0.1 localhost.localdomain localhost

#

192.161.180.94 mx1.example.com mx1
192.161.180.94 v.example.com  v
::1    localhost ip6-localhost ip6-loopback
EOF

cat /etc/hosts > /var/spool/postfix/etc/hosts

hostname mx1.example.com

# relogin to update PS1
su -

#
# get letsencrypt
#
# https://community.letsencrypt.org/t/using-le-with-postfix-dovecot-pop3-ssl/10289/2
# https://community.letsencrypt.org/t/simple-guide-using-lets-encrypt-ssl-certs-with-dovecot/2921/2
#
# http://nginx.org/en/linux_packages.html?_ga=1.165512447.1124031743.1468906423
#
# https://www.digitalocean.com/community/tutorials/how-to-secure-nginx-with-let-s-encrypt-on-ubuntu-14-04
# http://blog.aarhusworks.com/tutorial-how-to-obtain-and-add-letsencrypt-certificate-to-postfix-and-dovecot/

# add source

curl http://nginx.org/keys/nginx_signing.key | apt-key add -

cat <<'EOF' > /etc/apt/sources.list.d/nginx.list
# trusty for ubuntu 14.04, xenial for 16.04
deb http://nginx.org/packages/ubuntu/ trusty nginx
deb-src http://nginx.org/packages/ubuntu/ trusty nginx

EOF

# install nginx 1.10 (the stable version)
apt-get update && apt-get install -y nginx php5-fpm

# using www-data

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

nginx -t && service nginx restart

# configure for cert creation, http only

cat <<'EOF'> /etc/nginx/conf.d/default.conf
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    server_name _;
    
        access_log  /var/log/nginx/http.access.log  main;

        location / {
            #return         301 https://$server_name$request_uri;
            root   /usr/share/nginx/html;
            # index  index.html index.htm;
        }
        location ~ /.well-known {
            root   /usr/share/nginx/html;
            allow all;
        }
}
EOF

mkdir -p /etc/nginx/ssl

mkdir -p /usr/share/nginx/html/.well-known

nginx -t && service nginx restart

#

apt-get -y install git bc

mkdir -p /opt

git clone https://github.com/letsencrypt/letsencrypt /opt/letsencrypt

# config A record of example.com mx1.example.com www.example.com to ip of this nginx server

cd /opt/letsencrypt && ./letsencrypt-auto certonly -a webroot --webroot-path=/usr/share/nginx/html \
-d example.com -d mx1.example.com -d mail.example.com -d smtp.example.com  -d smtps.example.com \
-d pop3.example.com -d imap.example.com -d pop3s.example.com -d imaps.example.com

# 
# IMPORTANT NOTES:
#  - Congratulations! Your certificate and chain have been saved at
#    /etc/letsencrypt/live/example.com/fullchain.pem. Your cert
#    will expire on 2016-11-01. To obtain a new or tweaked version of
#    this certificate in the future, simply run letsencrypt-auto again.
#    To non-interactively renew *all* of your certificates, run
#    "letsencrypt-auto renew"
#  - If you lose your account credentials, you can recover through
#    e-mails sent to exampleuser@gmail.com.
#  - Your account credentials have been saved in your Certbot
#    configuration directory at /etc/letsencrypt. You should make a
#    secure backup of this folder now. This configuration directory will
#    also contain certificates and private keys obtained by Certbot so
#    making regular backups of this folder is ideal.
#  - If you like Certbot, please consider supporting our work by:
# 
#    Donating to ISRG / Let's Encrypt:   https://letsencrypt.org/donate
#    Donating to EFF:                    https://eff.org/donate-le
# 
# 

ls -alh /etc/letsencrypt/live/example.com/

# working server

cat <<'EOF'> /etc/nginx/conf.d/default.conf
server {
    # http2 server
    listen 443 ssl http2 default_server;
    listen [::]:443 ssl http2 default_server;

    server_name _;

    ssl_certificate /etc/letsencrypt/live/example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/example.com/privkey.pem;

    ssl_ciphers EECDH+CHACHA20:EECDH+AES128:RSA+AES128:EECDH+AES256:RSA+AES256:EECDH+3DES:RSA+3DES:!MD5;

    ssl_dhparam  /etc/nginx/ssl/dhparam.pem;

    ssl_session_cache shared:SSL:5m;

    ssl_session_timeout 1h;

        charset utf-8;

        access_log  /var/log/nginx/ssl.access.log  main;

        add_header Strict-Transport-Security "max-age=15768000; includeSubDomains: always;";

       location / {
           root   /usr/share/nginx/html;
           index  index.html index.htm;
       }

        # redirect server error pages to the static page /50x.html
        #
        error_page   500 502 503 504  /50x.html;
        location = /50x.html {
            root   /usr/share/nginx/html;
        }

        # proxy the PHP scripts to Apache listening on 127.0.0.1:80
        #
        #location ~ \.php$ {
        #    proxy_pass   http://127.0.0.1;
        #}

        # pass the PHP scripts to FastCGI server listening on 127.0.0.1:9000
        #
        #location ~ \.php$ {
        #    root           html;
        #    fastcgi_pass   127.0.0.1:9000;
        #    fastcgi_index  index.php;
        #    fastcgi_param  SCRIPT_FILENAME  /scripts$fastcgi_script_name;
        #    include        fastcgi_params;
        #}

        # deny access to .htaccess files, if Apache's document root
        # concurs with nginx's one
        #
        #location ~ /\.ht {
        #    deny  all;
        #}
}

server {
    listen 80 default_server;
    listen [::]:80 default_server;

    server_name _;
    
        access_log  /var/log/nginx/http.access.log  main;

        location / {
            # uncomment return 301 after letencrypto setup ok
            # should be http_host instead of server_name.
            return         301 https://$http_host$request_uri;
            root   /usr/share/nginx/html;
            # index  index.html index.htm;
        }
        location ~ /.well-known {
            root   /usr/share/nginx/html;
            allow all;
        }
}
EOF

nginx -t && service nginx restart

# enable 301 in http server after https is ok

apt-get update && apt-get install -y mailutils vmm dovecot-imapd dovecot-pop3d dovecot-sqlite postfix
#

# internet site

ssl cname: mx1.example.com
mail domain: example.com

pop3 cname: mail.example.com

cat <<'EOF' > /etc/mailname
example.com
EOF

cat <<'EOF' > /etc/aliases
# See man 5 aliases for format
postmaster:    root
EOF

#
# http://wiki2.dovecot.org/HowTo/PostfixAndDovecotSASL
# smtp sasl by dovecot

postconf -a
# cyrus
# dovecot

# catch all user
# http://serverfault.com/questions/164105/how-to-catchall-email-to-a-single-user-mailbox-in-postfix
#

useradd --home-dir /home/catchall --no-create-home --shell /usr/sbin/nologin catchall && mkdir -p /home/catchall && chown catchall:catchall /home/catchall && chmod 0755 /home/catchall

passwd catchall

id catchall

cat /etc/passwd| grep catchall


cat <<'EOF' >/sbin/postfixctl
#!/bin/bash
#
#
showlog(){
    sleep 3;tail -n 100 /var/log/mail.log | grep -C 10 'the Postfix mail system'
}
#
if [ "$1" = 'restart' ]
then
    $0 start
    exit $?
fi
if [ "$1" = 'status' ]
then
    ps axuww| grep master | grep postfix
    exit $?
fi
postfix check || exit 1
if [ "$1" = 'start' ]
then
    $0 stop >/dev/null 2>&1
    for aaa in `seq 20`
    do
        ps axuww| grep master | grep postfix || break
    done
    ps axuww| grep master | grep postfix
    if [ $? -eq 0 ]
    then
        echo "stop postfix for start failed."
        showlog
        exit 1
    fi
    postfix start
    sleep 3
    ps axuww| grep master | grep postfix
    if [ $? -ne 0 ]
    then
        echo "start postfix failed."
        showlog
        exit 1
    fi
    showlog
    exit 0
fi
if [ "$1" = 'stop' ]
then
    postfix stop
    for aaa in `seq 20`
    do
        ps axuww| grep master | grep postfix || break
    done
    ps axuww| grep master | grep postfix
    if [ $? -eq 0 ]
    then
        echo "stop postfix failed."
        showlog
        exit 1
    fi
    showlog
    exit 0
fi

EOF


chmod +x /sbin/postfixctl

cat <<'EOF'>/etc/postfix/main.cf
#
smtpd_banner = $myhostname ESMTP $mail_name (BAE)
biff = no
append_dot_mydomain = no
readme_directory = no
smtpd_tls_cert_file=/etc/letsencrypt/live/example.com/fullchain.pem
smtpd_tls_key_file=/etc/letsencrypt/live/example.com/privkey.pem
smtpd_use_tls=yes
smtpd_tls_session_cache_database = btree:${data_directory}/smtpd_scache
smtp_tls_session_cache_database = btree:${data_directory}/smtp_scache
myhostname = mx1.example.com
alias_maps = hash:/etc/aliases
alias_database = hash:/etc/aliases
myorigin = /etc/mailname
mydestination = example.com, mx1.example.com, localhost.example.com, localhost
relayhost = 
mynetworks = 127.0.0.0/8 [::ffff:127.0.0.0]/104 [::1]/128
home_mailbox = Maildir/
mailbox_command =
mailbox_size_limit = 0
recipient_delimiter = +
inet_interfaces = all
inet_protocols = ipv4
#
# http://serverfault.com/questions/164105/how-to-catchall-email-to-a-single-user-mailbox-in-postfix
#
luser_relay = catchall@example.com
local_recipient_maps =
#
smtpd_sasl_type = dovecot
# Can be an absolute path, or relative to $queue_directory
# Debian/Ubuntu users: Postfix is setup by default to run chrooted, so it is best to leave it as-is below
smtpd_sasl_path = private/auth
# On Debian Wheezy path must be relative and queue_directory defined
#queue_directory = /var/spool/postfix

# and the common settings to enable SASL:
smtpd_sasl_auth_enable = yes
# With Postfix version before 2.10, use smtpd_recipient_restrictions
smtpd_relay_restrictions = permit_mynetworks, permit_sasl_authenticated, reject_unauth_destination
#
EOF

postfix reload

cat <<'EOF' > /etc/postfix/master.cf
smtp      inet  n       -       -       -       -       smtpd
pickup    unix  n       -       -       60      1       pickup
cleanup   unix  n       -       -       -       0       cleanup
qmgr      unix  n       -       n       300     1       qmgr
tlsmgr    unix  -       -       -       1000?   1       tlsmgr
rewrite   unix  -       -       -       -       -       trivial-rewrite
bounce    unix  -       -       -       -       0       bounce
defer     unix  -       -       -       -       0       bounce
trace     unix  -       -       -       -       0       bounce
verify    unix  -       -       -       -       1       verify
flush     unix  n       -       -       1000?   0       flush
proxymap  unix  -       -       n       -       -       proxymap
proxywrite unix -       -       n       -       1       proxymap
smtp      unix  -       -       -       -       -       smtp
relay     unix  -       -       -       -       -       smtp
showq     unix  n       -       -       -       -       showq
error     unix  -       -       -       -       -       error
retry     unix  -       -       -       -       -       error
discard   unix  -       -       -       -       -       discard
local     unix  -       n       n       -       -       local
virtual   unix  -       n       n       -       -       virtual
lmtp      unix  -       -       -       -       -       lmtp
anvil     unix  -       -       -       -       1       anvil
scache    unix  -       -       -       -       1       scache
maildrop  unix  -       n       n       -       -       pipe
  flags=DRhu user=vmail argv=/usr/bin/maildrop -d ${recipient}
uucp      unix  -       n       n       -       -       pipe
  flags=Fqhu user=uucp argv=uux -r -n -z -a$sender - $nexthop!rmail ($recipient)
ifmail    unix  -       n       n       -       -       pipe
  flags=F user=ftn argv=/usr/lib/ifmail/ifmail -r $nexthop ($recipient)
bsmtp     unix  -       n       n       -       -       pipe
  flags=Fq. user=bsmtp argv=/usr/lib/bsmtp/bsmtp -t$nexthop -f$sender $recipient
scalemail-backend unix    -    n    n    -    2    pipe
  flags=R user=scalemail argv=/usr/lib/scalemail/bin/scalemail-store ${nexthop} ${user} ${extension}
mailman   unix  -       n       n       -       -       pipe
  flags=FR user=list argv=/usr/lib/mailman/bin/postfix-to-mailman.py
  ${nexthop} ${user}
# 
# submission inet n       -       -       -       -       smtpd
#   -o syslog_name=postfix/submission
#   -o smtpd_tls_wrappermode=no
#   -o smtpd_tls_security_level=encrypt
#   -o smtpd_sasl_auth_enable=yes
#   -o smtpd_recipient_restrictions=permit_mynetworks,permit_sasl_authenticated,reject
#   -o milter_macro_daemon_name=ORIGINATING
#   -o smtpd_sasl_type=dovecot
#   -o smtpd_sasl_path=private/auth
#
submission inet n - n - - smtpd
  -o smtpd_tls_security_level=encrypt
  -o smtpd_sasl_auth_enable=yes
  -o smtpd_sasl_type=dovecot
  -o smtpd_sasl_path=private/auth
  -o smtpd_sasl_security_options=noanonymous
  -o smtpd_sasl_local_domain=$myhostname
  -o smtpd_client_restrictions=permit_sasl_authenticated,reject
  -o smtpd_sender_restrictions=reject_sender_login_mismatch
  -o smtpd_recipient_restrictions=reject_non_fqdn_recipient,reject_unknown_recipient_domain,permit_sasl_authenticated,reject

smtps    inet  n       -       n       -       -       smtpd
      -o smtpd_tls_wrappermode=yes -o smtpd_sasl_auth_enable=yes -o smtpd_tls_security_level=encrypt

#
EOF

/sbin/postfixctl restart

# The important detail is one that can't be seen: The smtpd_recipient_restrictions is missing reject_unauth_destination, which is present as a default and restricts relaying.

#   
#   Aug  3 02:59:42 v postfix/smtpd[20890]: connect from mail-it0-f50.google.com[209.85.214.50]
#   Aug  3 02:59:43 v postfix/smtpd[20890]: 16421160B32: client=mail-it0-f50.google.com[209.85.214.50]
#   Aug  3 02:59:43 v postfix/cleanup[20895]: 16421160B32: message-id=<CA+_TYQEc6FQd7Bcx1Zww8zwE5BFMktcVFW-Yd+j0Dj=65JpZfA@mail.gmail.com>
#   Aug  3 02:59:43 v postfix/qmgr[20882]: 16421160B32: from=<testuser@gmail.com>, size=2479, nrcpt=1 (queue active)
#   Aug  3 02:59:43 v postfix/local[20896]: 16421160B32: to=<catchall@example.com>, orig_to=<test@example.com>, relay=local, delay=0.12, delays=0.11/0/0/0, dsn=2.0.0, 
#      status=sent (delivered to command: procmail -a "$EXTENSION")
#   Aug  3 02:59:43 v postfix/qmgr[20882]: 16421160B32: removed
#   Aug  3 02:59:43 v postfix/smtpd[20890]: disconnect from mail-it0-f50.google.com[209.85.214.50]
#   

# dovecot-imapd

cat <<'EOF' >/sbin/dovecotctl
#!/bin/bash
#
#
showlog(){
    sleep 3;tail -n 100 /var/log/mail.log | grep -C 10 'dovecot: master'
}
#
if [ "$1" = 'restart' ]
then
    $0 start
    exit $?
fi
if [ "$1" = 'status' ]
then
    ps axuww| grep /etc/dovecot/dovecot.conf | grep -v grep
    exit $?
fi
if [ "$1" = 'start' ]
then
    $0 stop >/dev/null 2>&1
    for aaa in `seq 20`
    do
        ps axuww| grep /etc/dovecot/dovecot.conf | grep -v grep || break
    done
    ps axuww| grep /etc/dovecot/dovecot.conf | grep -v grep
    if [ $? -eq 0 ]
    then
        echo "stop dovecot for start failed."
        showlog
        exit 1
    fi
    service dovecot start
    sleep 2
    ps axuww| grep /etc/dovecot/dovecot.conf | grep -v grep
    if [ $? -ne 0 ]
    then
        echo "start dovecot failed."
        showlog
        exit 1
    fi
    showlog
    exit 0
fi
if [ "$1" = 'stop' ]
then
    service dovecot stop
    for aaa in `seq 20`
    do
        ps axuww| grep /etc/dovecot/dovecot.conf | grep -v grep || break
    done
    ps axuww| grep /etc/dovecot/dovecot.conf | grep -v grep
    if [ $? -eq 0 ]
    then
        echo "stop dovecot failed."
        showlog
        exit 1
    fi
    showlog
    exit 0
fi

EOF

chmod +x /sbin/dovecotctl

# http://wiki.dovecot.org/MailboxSettings

test -f /etc/dovecot/dovecot.conf && mv /etc/dovecot/dovecot.conf /etc/dovecot/dovecot.conf.orig.$$

cat <<'EOF' > /etc/dovecot/dovecot.conf
#
ssl = required
disable_plaintext_auth = yes
# mail_privileged_group = mail
mail_location = maildir:~/Maildir
userdb {
  driver = passwd
}
passdb {
  args = %s
  driver = pam
}
protocols = "imap pop3"

# Aug  6 23:57:28 mx1 dovecot: imap(ivy): Warning: autocreate plugin is deprecated, use mailbox { auto } setting instead
#   plugin {
#     autocreate = Trash
#     autocreate2 = Sent
#     autosubscribe = Trash
#     autosubscribe2 = Sent
#   }

namespace inbox {
  #prefix = INBOX. # the namespace prefix isn't added again to the mailbox names.
  inbox = yes
  # ...

  mailbox Trash {
    auto = subscribe
    special_use = \Trash
  }
  mailbox Drafts {
    auto = subscribe
    special_use = \Drafts
  }
  mailbox Sent {
    auto = subscribe # autocreate and autosubscribe the Sent mailbox
    special_use = \Sent
  }
  mailbox "Sent Messages" {
    auto = subscribe
    special_use = \Sent
  }
  mailbox Spam {
    auto = create # autocreate Spam, but don't autosubscribe
    special_use = \Junk
  }
  mailbox virtual/All { # if you have a virtual "All messages" mailbox 
    auto = subscribe
    special_use = \All
  }
}

service auth {
    unix_listener /var/spool/postfix/private/auth {
    group = postfix
    mode = 0660
    user = postfix
  }
}
# Outlook Express and Windows Mail works only with LOGIN mechanism, not the standard PLAIN:
auth_mechanisms = plain login

ssl=required
# same as postfix pem
ssl_cert = </etc/letsencrypt/live/example.com/fullchain.pem
ssl_key = </etc/letsencrypt/live/example.com/privkey.pem

local_name mx1.example.com {
  ssl_cert = </etc/letsencrypt/live/example.com/fullchain.pem
  ssl_key = </etc/letsencrypt/live/example.com/privkey.pem
}

local_name mail.example.com {
  ssl_cert = </etc/letsencrypt/live/example.com/fullchain.pem
  ssl_key = </etc/letsencrypt/live/example.com/privkey.pem
}

local_name imaps.example.com {
  ssl_cert = </etc/letsencrypt/live/example.com/fullchain.pem
  ssl_key = </etc/letsencrypt/live/example.com/privkey.pem
}

EOF

/sbin/dovecotctl restart

newaliases

/sbin/postfixctl restart 
/sbin/dovecotctl restart

#

cat <<'EOF'>/usr/sbin/addmail
#!/bin/bash
if [ $(id -u) -ne 0 ]
then
    sudo $0 $@
    exit $?
fi
USER="$1"
test -z "$USER" && echo "USAGE: $0 <username>" && exit 1

id -u $USER >/dev/null 2>&1
if [ $? -eq 0 ]
then
    echo "ERROR: user $USER already exist."
    exit 1
fi

useradd --home-dir /home/${USER} --no-create-home --shell /usr/sbin/nologin ${USER} && mkdir -p /home/${USER} && chown ${USER}:${USER} /home/${USER} && chmod 0755 /home/${USER}
id -u $USER >/dev/null 2>&1
if [ $? -ne 0 ]
then
    echo "ERROR: add user $USER failed."
    exit 1
fi

passwd ${USER}

id ${USER}

EOF

chmod +x /usr/sbin/addmail

#
# add cron renew
# 
# crontab -e
# # m h  dom mon dow   command
# 1 3 * * 1 /opt/letsencrypt/letsencrypt-auto renew
# 
# 5 3 * * 1 /etc/init.d/postfix reload  
# 10 3 * * 1 /usr/sbin/dovecot reload  
#

#
# webmail
#
# https://www.howtoforge.com/the-perfect-server-ubuntu-14.04-nginx-bind-mysql-php-postfix-dovecot-and-ispconfig3-p4
#
service apache2 stop

update-rc.d -f apache2 remove

# using nginx+php-fpm, kick apache2 away

apt-get update

# https://www.howtoforge.com/installation-and-configuration-of-rainloop-in-debian-7-wheezy

apt-get install -y roundcube roundcube-sqlite3 roundcube-core roundcube-plugins roundcube-plugins-extra sqlite3 php5-fpm php5-mcrypt php5-intl php-apc php5-curl php5-sqlite

# use db-config and select sqlite3

# NOTE: using sqlite3 database

mkdir -p /opt/webmail/rainlooproot && cd /opt/webmail/ && \
wget http://repository.rainloop.net/v2/webmail/rainloop-latest.zip && \
cd rainlooproot && unzip ../rainloop-latest.zip

chown -R root:root /opt/webmail/rainlooproot
chown -R www-data:www-data /opt/webmail/rainlooproot/data

chmod -R 0755 /opt/webmail/rainlooproot
chmod -R 0770 /opt/webmail/rainlooproot/data

# php-fpm configure: /etc/php5/fpm/php-fpm.conf
# listner: /var/run/php5-fpm.sock

cat <<'EOF'> /etc/nginx/conf.d/mail.example.com.conf
server {
# http2 server
    listen 443 ssl http2;
    listen [::]:443 ssl http2;

    server_name mail.example.com;

    ssl_certificate /etc/letsencrypt/live/example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/example.com/privkey.pem;

    ssl_ciphers EECDH+CHACHA20:EECDH+AES128:RSA+AES128:EECDH+AES256:RSA+AES256:EECDH+3DES:RSA+3DES:!MD5;

    ssl_dhparam  /etc/nginx/ssl/dhparam.pem;

    ssl_session_cache shared:SSL:5m;

    ssl_session_timeout 1h;

    charset utf-8;

    access_log  /var/log/nginx/ssl.mail.example.com.access.log  main;

    add_header Strict-Transport-Security "max-age=15768000; includeSubDomains: always;";

    error_page   500 502 503 504  /50x.html;
    location = /50x.html {
        root   /usr/share/nginx/html;
    }
    root /opt/webmail/rainlooproot;
    index index.php;

    location / {
        try_files $uri $uri/ /index.php?$args;
    }
    # deny access to .htaccess files, if Apache's document root
    # concurs with nginx's one
    #
    location ~ /\.ht {
        deny  all;
    }
    location ^~ /data/ {
        deny  all;
    }
    location ~ \.php$ {
        try_files $uri =404;
        include fastcgi_params;
        #fastcgi_pass unix:/var/run/php5-fpm.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $document_root/$fastcgi_script_name;
        fastcgi_pass 127.0.0.1:9000;
    }
}
EOF

nginx -t && service nginx restart

# access https://mail.example.com/installer to initial

# configure all db to sqlite

#
# all ok
#
