#
# http://nginx.org/en/linux_packages.html?_ga=1.165512447.1124031743.1468906423
#
# https://www.digitalocean.com/community/tutorials/how-to-secure-nginx-with-let-s-encrypt-on-ubuntu-14-04


# add source

curl http://nginx.org/keys/nginx_signing.key | apt-key add -

cat <<'EOF' > /etc/apt/sources.list.d/nginx.list
# trusty for ubuntu 14.04, xenial for 16.04
deb http://nginx.org/packages/ubuntu/ trusty nginx
deb-src http://nginx.org/packages/ubuntu/ trusty nginx

EOF

# install nginx 1.10 (the stable version)
apt-get update && apt-get install -y nginx

cat <<'EOF'> /etc/nginx/conf.d/default.conf
server {
	# http2 server
	listen 443 ssl http2 default_server;
	listen [::]:443 ssl http2 default_server;

	server_name _;

	ssl_certificate /etc/nginx/ssl/http2.horde.live.crt.pem;
	ssl_certificate_key /etc/nginx/ssl/http2.horde.live.key.pem;

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
    	    # return         301 https://$server_name$request_uri;
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

apt-get -y install git bc

mkdir -p /opt

git clone https://github.com/letsencrypt/letsencrypt /opt/letsencrypt

# config A record of horde.live http2.horde.live www.horde.live to ip of this nginx server
cd /opt/letsencrypt && ./letsencrypt-auto certonly -a webroot --webroot-path=/usr/share/nginx/html -d horde.live -d http2.horde.live -d www.horde.live

ls -alh /etc/letsencrypt/live/horde.live/

cat /etc/letsencrypt/live/horde.live/fullchain.pem >/etc/nginx/ssl/http2.horde.live.crt.pem
cat /etc/letsencrypt/live/horde.live/privkey.pem >/etc/nginx/ssl/http2.horde.live.key.pem

chmod 0644 /etc/nginx/ssl/http2.horde.live.crt.pem
chmod 0600 /etc/nginx/ssl/http2.horde.live.key.pem

nginx -t && service nginx reload

# enable 301 in http server after https is ok

