# Домашнее задание 4 (OTUS Linux 2024 - 06)

Что нужно сделать?
 - добавить в Vagrantfile еще дисков;
 - собрать R0/R5/R10 на выбор;
 - прописать собранный рейд в конф, чтобы рейд собирался при загрузке;
 - сломать/починить raid;
 - создать GPT раздел и 5 партиций.

На проверку отправьте:
 - измененный Vagrantfile;
 - скрипт для создания рейда;
 - конф для автосборки рейда при загрузке.

------

#### Ход выполнения работы:

Проверяем подключение новых дисков:
```
[vagrant@mdadm ~]$ lsblk | grep -v "sda"
NAME   MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sdb      8:16   0  256M  0 disk 
sdc      8:32   0  256M  0 disk 
sdd      8:48   0  256M  0 disk 
sde      8:64   0  256M  0 disk 
sdf      8:80   0  256M  0 disk 
```

Зануляем суперблоки:
```
[vagrant@mdadm ~]$ sudo mdadm --zero-superblock --force /dev/sd{b,c,d,e,f}
mdadm: Unrecognised md component device - /dev/sdb
mdadm: Unrecognised md component device - /dev/sdc
mdadm: Unrecognised md component device - /dev/sdd
mdadm: Unrecognised md component device - /dev/sde
mdadm: Unrecognised md component device - /dev/sdf
```

Создаем RAID10:
```
[vagrant@mdadm ~]$ sudo mdadm --create /dev/md10 --level=10 --raid-devices=4 /dev/sd[b-e]
mdadm: Defaulting to version 1.2 metadata
mdadm: array /dev/md10 started.
```

Проверка созданного raid массива
```
[vagrant@mdadm ~]$ cat /proc/mdstat
Personalities : [raid10] 
md10 : active raid10 sde[3] sdd[2] sdc[1] sdb[0]
      520192 blocks super 1.2 512K chunks 2 near-copies [4/4] [UUUU]   
unused devices: <none>

[vagrant@mdadm ~]$ lsblk | grep -v "sda"
NAME   MAJ:MIN RM  SIZE RO TYPE   MOUNTPOINT
sdb      8:16   0  256M  0 disk   
└─md10   9:10   0  508M  0 raid10 
sdc      8:32   0  256M  0 disk   
└─md10   9:10   0  508M  0 raid10 
sdd      8:48   0  256M  0 disk   
└─md10   9:10   0  508M  0 raid10 
sde      8:64   0  256M  0 disk   
└─md10   9:10   0  508M  0 raid10 
sdf      8:80   0  256M  0 disk  
```


Cохраняем конфигурацию RAID10, чтобы во время загрузки системы происходило ее считывание:
```
[vagrant@mdadm ~]$ sudo su
[root@mdadm vagrant]# mdadm --detail --scan > /etc/mdadm.conf
[root@mdadm vagrant]# exit
exit
[vagrant@mdadm ~]$ cat /etc/mdadm.conf
ARRAY /dev/md10 metadata=1.2 name=mdadm:10 UUID=13167a20:4030ba3f:55df8757:d05dff2d
```

Устанавливаем parted:
```
[vagrant@mdadm ~]$ sudo apt-get update
[vagrant@mdadm ~]$ sudo apt-get install parted -y
```

Создаем раздел GPT на RAID10:
```
[vagrant@mdadm ~]$ sudo parted -s /dev/md10 mklabel gpt
[vagrant@mdadm ~]$ sudo blkid | grep md10
/dev/md10: PTUUID="b252d558-3e4e-4e2d-8530-57ab9a21ceca" PTTYPE="gpt"
```

Создаем 5 партиций:
```
[vagrant@mdadm ~]$ sudo parted /dev/md10 mkpart primary ext4 0% 20%
[vagrant@mdadm ~]$ sudo parted /dev/md10 mkpart primary ext4 20% 40%
[vagrant@mdadm ~]$ sudo parted /dev/md10 mkpart primary ext4 40% 60%
[vagrant@mdadm ~]$ sudo parted /dev/md10 mkpart primary ext4 60% 80%
[vagrant@mdadm ~]$ sudo parted /dev/md10 mkpart primary ext4 80% 100%
```

Проверяем:
```
[vagrant@mdadm ~]$ lsblk                                                  
NAME       MAJ:MIN RM  SIZE RO TYPE   MOUNTPOINT
sda          8:0    0 29,3G  0 disk   
└─sda1       8:1    0   10G  0 part   /
sdb          8:16   0  256M  0 disk   
└─md10       9:10   0  508M  0 raid10 
  ├─md10p1 259:5    0  101M  0 part   
  ├─md10p2 259:6    0  101M  0 part   
  ├─md10p3 259:7    0  102M  0 part   
  ├─md10p4 259:8    0  101M  0 part   
  └─md10p5 259:9    0  101M  0 part   
sdc          8:32   0  256M  0 disk   
└─md10       9:10   0  508M  0 raid10 
  ├─md10p1 259:5    0  101M  0 part   
  ├─md10p2 259:6    0  101M  0 part   
  ├─md10p3 259:7    0  102M  0 part   
  ├─md10p4 259:8    0  101M  0 part   
  └─md10p5 259:9    0  101M  0 part   
sdd          8:48   0  256M  0 disk   
└─md10       9:10   0  508M  0 raid10 
  ├─md10p1 259:5    0  101M  0 part   
  ├─md10p2 259:6    0  101M  0 part   
  ├─md10p3 259:7    0  102M  0 part   
  ├─md10p4 259:8    0  101M  0 part   
  └─md10p5 259:9    0  101M  0 part   
sde          8:64   0  256M  0 disk   
└─md10       9:10   0  508M  0 raid10 
  ├─md10p1 259:5    0  101M  0 part   
  ├─md10p2 259:6    0  101M  0 part   
  ├─md10p3 259:7    0  102M  0 part   
  ├─md10p4 259:8    0  101M  0 part   
  └─md10p5 259:9    0  101M  0 part   
sdf          8:80   0  256M  0 disk
```

Создаем файловую систему в разделах:
```
[vagrant@mdadm ~]$ for i in $(seq 1 5); do sudo mkfs.ext4 /dev/md10p$i; done
```

Монитруем новые разделы:
```
[vagrant@mdadm ~]$ sudo mkdir -p /raid/part{1,2,3,4,5}
[vagrant@mdadm ~]$ for i in $(seq 1 5); do sudo mount /dev/md10p$i /raid/part$i; done
```

Проверяем что разделы смонитрованы:
```
[vagrant@mdadm ~]$ lsblk
NAME       MAJ:MIN RM  SIZE RO TYPE   MOUNTPOINT
sda          8:0    0 29,3G  0 disk   
└─sda1       8:1    0   10G  0 part   /
sdb          8:16   0  256M  0 disk   
└─md10       9:10   0  508M  0 raid10 
  ├─md10p1 259:5    0  101M  0 part   /raid/part1
  ├─md10p2 259:6    0  101M  0 part   /raid/part2
  ├─md10p3 259:7    0  102M  0 part   /raid/part3
  ├─md10p4 259:8    0  101M  0 part   /raid/part4
  └─md10p5 259:9    0  101M  0 part   /raid/part5
sdc          8:32   0  256M  0 disk   
└─md10       9:10   0  508M  0 raid10 
  ├─md10p1 259:5    0  101M  0 part   /raid/part1
  ├─md10p2 259:6    0  101M  0 part   /raid/part2
  ├─md10p3 259:7    0  102M  0 part   /raid/part3
  ├─md10p4 259:8    0  101M  0 part   /raid/part4
  └─md10p5 259:9    0  101M  0 part   /raid/part5
sdd          8:48   0  256M  0 disk   
└─md10       9:10   0  508M  0 raid10 
  ├─md10p1 259:5    0  101M  0 part   /raid/part1
  ├─md10p2 259:6    0  101M  0 part   /raid/part2
  ├─md10p3 259:7    0  102M  0 part   /raid/part3
  ├─md10p4 259:8    0  101M  0 part   /raid/part4
  └─md10p5 259:9    0  101M  0 part   /raid/part5
sde          8:64   0  256M  0 disk   
└─md10       9:10   0  508M  0 raid10 
  ├─md10p1 259:5    0  101M  0 part   /raid/part1
  ├─md10p2 259:6    0  101M  0 part   /raid/part2
  ├─md10p3 259:7    0  102M  0 part   /raid/part3
  ├─md10p4 259:8    0  101M  0 part   /raid/part4
  └─md10p5 259:9    0  101M  0 part   /raid/part5
sdf          8:80   0  256M  0 disk
```

Заполняем fstab
```
[vagrant@mdadm ~]$ sudo su
[root@mdadm vagrant]# echo "" >> /etc/fstab
[root@mdadm vagrant]# echo "/dev/md10p1 /raid/part1 ext4 defaults 0 0" >> /etc/fstab
[root@mdadm vagrant]# echo "/dev/md10p2 /raid/part2 ext4 defaults 0 0" >> /etc/fstab
[root@mdadm vagrant]# echo "/dev/md10p3 /raid/part3 ext4 defaults 0 0" >> /etc/fstab
[root@mdadm vagrant]# echo "/dev/md10p4 /raid/part4 ext4 defaults 0 0" >> /etc/fstab
[root@mdadm vagrant]# echo "/dev/md10p5 /raid/part5 ext4 defaults 0 0" >> /etc/fstab
```

```
[root@mdadm vagrant]# exit
exit
[vagrant@mdadm ~]$ cat /etc/fstab
proc            /proc                   proc    nosuid,noexec,gid=proc          0 0
devpts          /dev/pts                devpts  nosuid,noexec,gid=tty,mode=620  0 0
tmpfs           /tmp                    tmpfs   nosuid                          0 0
UUID=c22ec7d9-470c-4ea2-a6a3-19e6ed390bf3       /       ext4    relatime        1       1
/dev/sr0        /media/ALTLinux udf,iso9660     ro,noauto,user,utf8,nofail,comment=x-gvfs-show  0 0
#VAGRANT-BEGIN
# The contents below are automatically generated by Vagrant. Do not modify.
vagrant /vagrant vboxsf uid=500,gid=500,_netdev 0 0
#VAGRANT-END

/dev/md10p1 /raid/part1 ext4 defaults 0 0
/dev/md10p2 /raid/part2 ext4 defaults 0 0
/dev/md10p3 /raid/part3 ext4 defaults 0 0
/dev/md10p4 /raid/part4 ext4 defaults 0 0
/dev/md10p5 /raid/part5 ext4 defaults 0 0
```

Создаем файлы в разделах:
```
[vagrant@mdadm ~]$ sudo touch /raid/part1/part1file.txt
[vagrant@mdadm ~]$ sudo touch /raid/part2/part2file.txt
[vagrant@mdadm ~]$ sudo touch /raid/part3/part3file.txt
[vagrant@mdadm ~]$ sudo touch /raid/part4/part4file.txt
[vagrant@mdadm ~]$ sudo touch /raid/part5/part5file.txt
```

Ломаем RAID10, убираем диск /dev/sdd:
```
[vagrant@mdadm ~]$ sudo mdadm /dev/md10 --fail /dev/sdd
mdadm: set /dev/sdd faulty in /dev/md10
```

Проверяем:
```
[vagrant@mdadm ~]$ cat /proc/mdstat
Personalities : [raid10] 
md10 : active raid10 sde[3] sdd[2](F) sdc[1] sdb[0]
      520192 blocks super 1.2 512K chunks 2 near-copies [4/3] [UU_U]
unused devices: <none>
```

```
[vagrant@mdadm ~]$ sudo mdadm -D /dev/md10
/dev/md10:
           Version : 1.2
     Creation Time : Sun Jul 21 15:36:25 2024
        Raid Level : raid10
        Array Size : 520192 (508.00 MiB 532.68 MB)
     Used Dev Size : 260096 (254.00 MiB 266.34 MB)
      Raid Devices : 4
     Total Devices : 4
       Persistence : Superblock is persistent

       Update Time : Sun Jul 21 16:39:57 2024
             State : clean, degraded 
    Active Devices : 3
   Working Devices : 3
    Failed Devices : 1
     Spare Devices : 0

            Layout : near=2
        Chunk Size : 512K

Consistency Policy : resync

              Name : mdadm:10  (local to host mdadm)
              UUID : 13167a20:4030ba3f:55df8757:d05dff2d
            Events : 19

    Number   Major   Minor   RaidDevice State
       0       8       16        0      active sync set-A   /dev/sdb
       1       8       32        1      active sync set-B   /dev/sdc
       -       0        0        2      removed
       3       8       64        3      active sync set-B   /dev/sde

       2       8       48        -      faulty   /dev/sdd
```

Удаляем "сломанный диск":
```
[vagrant@mdadm ~]$ sudo mdadm /dev/md10 --remove /dev/sdd
mdadm: hot removed /dev/sdd from /dev/md10
```

Вставляем новый диск /dev/sdf:
```
[vagrant@mdadm ~]$ sudo mdadm /dev/md10 --add /dev/sdf
mdadm: added /dev/sdf
```

Проверяем:
```
[vagrant@mdadm ~]$ cat /proc/mdstat
Personalities : [raid10] 
md10 : active raid10 sdf[4] sde[3] sdc[1] sdb[0]
      520192 blocks super 1.2 512K chunks 2 near-copies [4/4] [UUUU]
unused devices: <none>
```

```
[vagrant@mdadm ~]$ sudo mdadm -D /dev/md10
/dev/md10:
           Version : 1.2
     Creation Time : Sun Jul 21 15:36:25 2024
        Raid Level : raid10
        Array Size : 520192 (508.00 MiB 532.68 MB)
     Used Dev Size : 260096 (254.00 MiB 266.34 MB)
      Raid Devices : 4
     Total Devices : 4
       Persistence : Superblock is persistent

       Update Time : Sun Jul 21 16:42:38 2024
             State : clean 
    Active Devices : 4
   Working Devices : 4
    Failed Devices : 0
     Spare Devices : 0

            Layout : near=2
        Chunk Size : 512K

Consistency Policy : resync

              Name : mdadm:10  (local to host mdadm)
              UUID : 13167a20:4030ba3f:55df8757:d05dff2d
            Events : 39

    Number   Major   Minor   RaidDevice State
       0       8       16        0      active sync set-A   /dev/sdb
       1       8       32        1      active sync set-B   /dev/sdc
       4       8       80        2      active sync set-A   /dev/sdf
       3       8       64        3      active sync set-B   /dev/sde
```


Перезагружаемся и проверяем всё ли работает:
```
[vagrant@mdadm ~]$ sudo reboot
Connection to 127.0.0.1 closed by remote host.
seafores@ubuntu-pc:~/OTUS_Linux_2024/HW4$ vagrant ssh
Last login: Sun Jul 21 15:29:57 2024 from 10.0.2.2
[vagrant@mdadm ~]$ ls /raid/*/*
/raid/part1/part1file.txt  /raid/part2/part2file.txt  /raid/part3/part3file.txt  /raid/part4/part4file.txt  /raid/part5/part5file.txt
ls: невозможно открыть каталог '/raid/part1/lost+found': Отказано в доступе
ls: невозможно открыть каталог '/raid/part2/lost+found': Отказано в доступе
ls: невозможно открыть каталог '/raid/part3/lost+found': Отказано в доступе
ls: невозможно открыть каталог '/raid/part4/lost+found': Отказано в доступе
ls: невозможно открыть каталог '/raid/part5/lost+found': Отказано в доступе
```