# Домашнее задание 6 (OTUS Linux 2024 - 06)

1) Определить алгоритм с наилучшим сжатием:
- Определить какие алгоритмы сжатия поддерживает zfs (gzip, zle, lzjb, lz4);
- создать 4 файловых системы на каждой применить свой алгоритм сжатия;
- для сжатия использовать либо текстовый файл, либо группу файлов.

2) Определить настройки пула.
- С помощью команды zfs import собрать pool ZFS.
- Командами zfs определить настройки:
  - размер хранилища;  
  - тип pool;
  - значение recordsize;
  - какое сжатие используется;
  - какая контрольная сумма используется.

3) Работа со снапшотами:
- скопировать файл из удаленной директории;
- восстановить файл локально. zfs receive;
- найти зашифрованное сообщение в файле secret_message.


------


#### Ход выполнения работы:

##### 1) Определить алгоритм с наилучшим сжатием.

Проверяем подключение новых дисков:
```
seafores@echips-pc:~/OTUS_Linux_2024/HW6$ vagrant ssh
Last login: Sun Aug  4 11:10:11 2024 from 10.0.2.2
[vagrant@zfs ~]$ lsblk
NAME   MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda      8:0    0 29,3G  0 disk 
└─sda1   8:1    0   10G  0 part /
sdb      8:16   0  256M  0 disk 
sdc      8:32   0  256M  0 disk 
sdd      8:48   0  256M  0 disk 
sde      8:64   0  256M  0 disk 
sdf      8:80   0  256M  0 disk 
sdg      8:96   0  256M  0 disk 
sdh      8:112  0  256M  0 disk 
sdi      8:128  0  256M  0 disk
```


Для работы с локальным ZFS хранилищем должен быть установлен модуль ядра kernel-modules-zfs-std-def:
```
[root@zfs vagrant]# apt-get update
[root@zfs vagrant]# apt-get install kernel-modules-zfs-std-def zfs-utils wget
[root@zfs vagrant]# reboot
```


После перезагрузки включаем модуль:
```
modprobe zfs
```


Создаём 4 пула из двух дисков в режиме RAID1:
```
[root@zfs vagrant]# zpool create zfs_pool_1 mirror /dev/sdb /dev/sdc
[root@zfs vagrant]# zpool create zfs_pool_2 mirror /dev/sdd /dev/sde
[root@zfs vagrant]# zpool create zfs_pool_3 mirror /dev/sdf /dev/sdg
[root@zfs vagrant]# zpool create zfs_pool_4 mirror /dev/sdh /dev/sdi
```


Проверяем:
```
[root@zfs vagrant]# zpool list
NAME         SIZE  ALLOC   FREE  CKPOINT  EXPANDSZ   FRAG    CAP  DEDUP    HEALTH  ALTROOT
zfs_pool_1   240M   104K   240M        -         -     3%     0%  1.00x    ONLINE  -
zfs_pool_2   240M   104K   240M        -         -     3%     0%  1.00x    ONLINE  -
zfs_pool_3   240M    99K   240M        -         -     3%     0%  1.00x    ONLINE  -
zfs_pool_4   240M   104K   240M        -         -     3%     0%  1.00x    ONLINE  -
```


Добавим разные алгоритмы сжатия в каждую файловую систему:
```
[root@zfs vagrant]# zfs set compression=lzjb zfs_pool_1
[root@zfs vagrant]# zfs set compression=lz4 zfs_pool_2
[root@zfs vagrant]# zfs set compression=gzip-9 zfs_pool_3
[root@zfs vagrant]# zfs set compression=zle zfs_pool_4
```


Скачаем один и тот же текстовый файл во все пулы:
```
[root@zfs vagrant]# for i in {1..4}; do wget -P /zfs_pool_$i https://gutenberg.org/cache/epub/2600/pg2600.converter.log; done
```


Проверяем занятое место и компрессию:
```
[root@zfs vagrant]# zfs list
NAME         USED  AVAIL     REFER  MOUNTPOINT
zfs_pool_1  21.7M  98.3M     21.6M  /zfs_pool_1
zfs_pool_2  17.7M   102M     17.6M  /zfs_pool_2
zfs_pool_3  10.9M   109M     10.7M  /zfs_pool_3
zfs_pool_4  39.4M  80.6M     39.2M  /zfs_pool_4

[root@zfs vagrant]# ls -lh /zfs_pool_3/
итого 11M
-rw-r--r-- 1 root root 40M авг  2 10:54 pg2600.converter.log

[root@zfs vagrant]# zfs get all | grep compressratio | grep -v ref
zfs_pool_1  compressratio         1.81x                      -
zfs_pool_2  compressratio         2.23x                      -
zfs_pool_3  compressratio         3.65x                      -
zfs_pool_4  compressratio         1.00x                      -
```


##### Меньше всего места занял метод сжатия gzip-9: конечный размер 10.9M (изначальный 40М).


------


##### 2) Определить настройки пула.


Импортируем каталог:
```
[root@zfs vagrant]# wget -O archive.tar.gz --no-check-certificate 'https://drive.usercontent.google.com/download?id=1MvrcEp-WgAQe57aDEzxSRalPAwbNN1Bb&export=download' 
```


Проверяем, возможно ли импортировать данный каталог в пул:
```
[root@zfs vagrant]# tar -xzvf archive.tar.gz
zpoolexport/
zpoolexport/filea
zpoolexport/fileb
[root@zfs vagrant]# zpool import -d zpoolexport/
   pool: otus
     id: 6554193320433390805
  state: ONLINE
status: Some supported features are not enabled on the pool.
        (Note that they may be intentionally disabled if the
        'compatibility' property is set.)
 action: The pool can be imported using its name or numeric identifier, though
        some features will not be available without an explicit 'zpool upgrade'.
 config:

        otus                                 ONLINE
          mirror-0                           ONLINE
            /home/vagrant/zpoolexport/filea  ONLINE
            /home/vagrant/zpoolexport/fileb  ONLINE
```


Импортируем и проверяем:
```
[root@zfs vagrant]# zpool import -d zpoolexport/ otus
[root@zfs vagrant]# zpool list
NAME         SIZE  ALLOC   FREE  CKPOINT  EXPANDSZ   FRAG    CAP  DEDUP    HEALTH  ALTROOT
otus         480M  2.21M   478M        -         -     0%     0%  1.00x    ONLINE  -
zfs_pool_1   240M  21.7M   218M        -         -     5%     9%  1.00x    ONLINE  -
zfs_pool_2   240M  17.7M   222M        -         -     5%     7%  1.00x    ONLINE  -
zfs_pool_3   240M  10.9M   229M        -         -     4%     4%  1.00x    ONLINE  -
zfs_pool_4   240M  39.4M   201M        -         -     6%    16%  1.00x    ONLINE  -
```


##### Командами zfs определяем настройки нового пула:
  - размер хранилища:
  - тип pool
  - значение recordsize
  - какое сжатие используется
  - какая контрольная сумма используется
```
[root@zfs vagrant]# zfs get available otus
NAME  PROPERTY   VALUE  SOURCE
otus  available  350M   -
[root@zfs vagrant]# zfs get readonly otus
NAME  PROPERTY  VALUE   SOURCE
otus  readonly  off     default
[root@zfs vagrant]# zfs get recordsize otus
NAME  PROPERTY    VALUE    SOURCE
otus  recordsize  128K     local
[root@zfs vagrant]# zfs get compression otus
NAME  PROPERTY     VALUE           SOURCE
otus  compression  zle             local
[root@zfs vagrant]# zfs get checksum otus
NAME  PROPERTY  VALUE      SOURCE
otus  checksum  sha256     local
```


------


##### 3) Работа со снапшотами.


Скачаем файл, указанный в задании:
```
[root@zfs vagrant]# wget -O otus_task2.file --no-check-certificate https://drive.usercontent.google.com/download?id=1wgxjih8YZ-cqLqaZVa0lA3h3Y029c3oI&export=download
```


Восстановим файловую систему из снапшота:
```
[root@zfs vagrant]# zfs receive otus/test@today < otus_task2.file
```


Смотрим содержимое найденного файла:
```
[root@zfs vagrant]# cat /otus/test/task1/file_mess/secret_message
https://otus.ru/lessons/linux-hl/
```