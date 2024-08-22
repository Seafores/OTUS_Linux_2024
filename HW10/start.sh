#!/bin/bash

cat <<\EOF > /etc/default/log.file
авг 22 16:50:11 systemd systemd[4417]: Stopped target Main User Target.
авг 22 16:50:11 systemd systemd[4417]: Stopped target Basic System.
авг 22 16:50:11 systemd systemd[4417]: Stopped target Paths.
авг 22 16:50:11 systemd systemd[4417]: Stopped target Sockets.
авг 22 16:50:11 systemd systemd[4417]: Stopped target Timers.
авг 22 16:50:11 systemd systemd[4417]: Stopped Daily Cleanup of User's Temporary Directories.
авг 22 16:50:11 systemd systemd[4417]: Closed D-Bus User Message Bus Socket.
авг 22 16:50:11 systemd systemd[4417]: Stopped Create User's Volatile Files and Directories.
авг 22 16:50:11 systemd systemd[4417]: Removed slice User Application Slice.
авг 22 16:50:11 systemd systemd[4417]: Reached target Shutdown.
авг 22 16:50:11 systemd systemd[4417]: Finished Exit the Session.
авг 22 16:50:11 systemd systemd[4417]: Reached target Exit the Session.
EOF

cat <<\EOF > /etc/default/watchlog.sh
#!/bin/bash

WORD=$1
LOG=$2
DATE=$(date)

if grep -q $WORD $LOG; then
  logger "$DATE: I found word \"$WORD\", Seafores!"
else
  exit 0
fi
EOF


chmod +x /etc/default/watchlog.sh


cat <<\EOF > /etc/systemd/system/watchlog.service
[Unit]
Description=Watchlog service

[Service]
Type=oneshot
ExecStart=/etc/default/watchlog.sh Sockets /etc/default/log.file

[Install]
EOF


cat <<\EOF > /etc/systemd/system/watchlog.timer
[Unit]
Description=Run watchlog script every 30 second

[Timer]
OnUnitActiveSec=30
Unit=watchlog.service

[Install]
WantedBy=multi-user.target
EOF


apt-get update
apt-get install spawn-fcgi php8.2 php8.2-cgi apache2 apache2-mod_fcgid nginx -y


mkdir -p /etc/spawn-fcgi/


cat <<\EOF > /etc/spawn-fcgi/fcgi.conf
SOCKET=/var/run/php-fcgi.sock
OPTIONS="-u vagrant -g vagrant -s $SOCKET -S -M 0600 -C 32 -F 1 -- /usr/bin/php-cgi-8.2"
EOF


cat <<\EOF > /etc/systemd/system/spawn-fcgi.service
[Unit]
Description=Spawn-fcgi startup service by Otus
After=network.target

[Service]
Type=simple
PIDFile=/var/run/spawn-fcgi.pid
EnvironmentFile=/etc/spawn-fcgi/fcgi.conf
ExecStart=/usr/bin/spawn-fcgi -n $OPTIONS
KillMode=process

[Install]
WantedBy=multi-user.target
EOF


cat <<\EOF > /etc/systemd/system/nginx@.service
[Unit]
Description=A high performance web server and a reverse proxy server
Documentation=man:nginx(8)
After=network.target nss-lookup.target

[Service]
Type=forking
PIDFile=/run/nginx-%I.pid
ExecStartPre=/usr/sbin/nginx -t -c /etc/nginx/nginx-%I.conf -q -g 'daemon on; master_process on;'
ExecStart=/usr/sbin/nginx -c /etc/nginx/nginx-%I.conf -g 'daemon on; master_process on;'
ExecReload=/usr/sbin/nginx -c /etc/nginx/nginx-%I.conf -g 'daemon on; master_process on;' -s reload
ExecStop=-/sbin/start-stop-daemon --quiet --stop --retry QUIT/5 --pidfile /run/nginx-%I.pid
TimeoutStopSec=5
KillMode=mixed

[Install]
WantedBy=multi-user.target
EOF


cat <<\EOF > /etc/nginx/nginx-first.conf
include /etc/nginx/modules-enabled.d/*.conf;
worker_processes  11;
error_log   /var/log/nginx/error.log;
events {
        worker_connections  1024;
}
pid /run/nginx-first.pid;
http {
        server {
		      listen 9001;
	      }
        proxy_temp_path /var/spool/nginx/tmp/proxy;
        fastcgi_temp_path /var/spool/nginx/tmp/fastcgi;
        client_body_temp_path /var/spool/nginx/tmp/client;
        include       /etc/nginx/mime.types;
        default_type  application/octet-stream;
        sendfile  on;
        gzip  on;
        gzip_types text/plain text/css text/xml application/x-javascript application/atom+xml;
}
EOF


cat <<\EOF > /etc/nginx/nginx-second.conf
include /etc/nginx/modules-enabled.d/*.conf;
worker_processes  12;
error_log   /var/log/nginx/error.log;
events {
        worker_connections  1024;
}
pid /run/nginx-second.pid;
http {
        server {
		      listen 9002;
	      }
        proxy_temp_path /var/spool/nginx/tmp/proxy;
        fastcgi_temp_path /var/spool/nginx/tmp/fastcgi;
        client_body_temp_path /var/spool/nginx/tmp/client;
        include       /etc/nginx/mime.types;
        default_type  application/octet-stream;
        sendfile  on;
        gzip  on;
        gzip_types text/plain text/css text/xml application/x-javascript application/atom+xml;
}
EOF


systemctl daemon-reload
systemctl start watchlog.timer
systemctl start watchlog.service
systemctl start spawn-fcgi.service
systemctl start nginx@first
systemctl start nginx@second