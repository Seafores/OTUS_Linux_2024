# На проверку отправьте:
# - измененный Vagrantfile;
# - скрипт для создания рейда;

sudo mdadm --zero-superblock --force /dev/sd{b,c,d,e,f}
sudo mdadm --create /dev/md10 --level=10 --raid-devices=4 /dev/sd[b-e]
sudo mdadm --detail --scan > /etc/mdadm.conf