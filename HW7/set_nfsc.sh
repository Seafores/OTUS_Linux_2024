#!/bin/bash

apt-get update
apt-get install nfs-clients nfs-utils -y
```

systemctl enable --now rpc-statd
mount -t nfs -o nfsvers=3  192.168.56.10:/mnt/share/ /mnt
```
cat << EOF > /lib/systemd/system/nfs-shared.service
[Unit]
Description=Mount NFS share
Requires=network-online.target
After=network-online.target

[Service]
Type=oneshot
RemainAfterExit=true
ExecStart=/bin/mount 192.168.56.10:/mnt/share/ /mnt -o fsc,hard
ExecStop=/bin/umount /mnt/shared
TimeoutStopSec=5

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload 
systemctl enable nfs-shared.service