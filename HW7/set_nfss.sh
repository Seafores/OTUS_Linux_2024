#!/bin/bash

apt-get update
apt-get install nfs-server -y

mkdir -p /mnt/share/upload
touch /mnt/share/upload/test_file_from_server
chown -R nobody:nobody /mnt/share
chmod -R 777 /mnt/share

echo "/mnt/share 192.168.56.11/32(rw,sync,root_squash)" > /etc/exports

exportfs -r
exportfs -s 
systemctl enable  nfs-server.service --now