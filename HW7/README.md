# Домашнее задание 7 (OTUS Linux 2024 - 06)

Описание домашнего задания 
- vagrant up должен поднимать 2 настроенных виртуальных машины (сервер NFS и клиента) без дополнительных ручных действий;
- на сервере NFS должна быть подготовлена и экспортирована директория; 
- в экспортированной директории должна быть поддиректория с именем upload с правами на запись в неё; 
- экспортированная директория должна автоматически монтироваться на клиенте при старте виртуальной машины (systemd, autofs или fstab — любым способом);
- монтирование и работа NFS на клиенте должна быть организована с использованием NFSv3.

Статус "Принято" ставится при выполнении основных требований:
- vagrant up должен поднимать 2 виртуалки: сервер и клиент;
- на сервере должна быть настроена директория для отдачи по NFS;
- на клиенте она должна автоматически монтироваться при старте (fstab или autofs);
- в сетевой директории должна быть папка upload с правами на запись;
- требования для NFS: NFS версии 3.


------


#### Ход выполнения работы:

##### Настройка сервера:

Подключаемся к серверу:
```
seafores@echips-pc:~/VM/HW7$ vagrant ssh nfss
[vagrant@nfss ~]$ sudo su
```


Устанавливаем серверную часть:
```
[root@nfss vagrant]# apt-get update
[root@nfss vagrant]# apt-get install nfs-server
```


Создаем каталог и выдаем nobody права на него, создаем тестовый файл:
```
[root@nfss vagrant]# mkdir -p /mnt/share/upload
[root@nfss vagrant]# touch /mnt/share/upload/test_file_from_server
[root@nfss vagrant]# chown -R nobody:nobody /mnt/share
[root@nfss vagrant]# chmod -R 777 /mnt/share
```


Выполняем настройку NFS (синтаксис NFS 3), разрешаем подключение с клиента nfsc:
```
[root@nfss vagrant]# echo "/mnt/share 192.168.56.11/32(rw,sync,root_squash)" > /etc/exports
```


Применяем настройки и запускам службу:
```
[root@nfss vagrant]# exportfs -r
exportfs: /etc/exports [1]: Neither 'subtree_check' or 'no_subtree_check' specified for export "192.168.56.11/32:/mnt/share".
  Assuming default behaviour ('no_subtree_check').
  NOTE: this default has changed since nfs-utils version 1.0.x

[root@nfss vagrant]# exportfs -s 
/mnt/share  192.168.56.11/32(sync,wdelay,hide,no_subtree_check,sec=sys,rw,root_squash,no_all_squash)

[root@nfss vagrant]# systemctl enable  nfs-server.service --now 
Created symlink /etc/systemd/system/multi-user.target.wants/nfs-server.service → /lib/systemd/system/nfs-server.service.
```


##### Настройка клиента:


Подключаемся к клиенту:
```
seafores@echips-pc:~/VM/HW7$ vagrant ssh nfsc
[vagrant@nfsc ~]$ sudo su
```


Устанавливаем необходимое ПО:
```
[root@nfsc vagrant]# apt-get update
[root@nfsc vagrant]# apt-get install nfs-clients nfs-utils 
```


Подключаем rpc-statd и вручную монтируем сетевую шару:
```
[root@nfsc vagrant]# systemctl enable --now rpc-statd
[root@nfsc vagrant]# mount -t nfs -o nfsvers=3  192.168.56.10:/mnt/share/ /mnt
```


Проверяем что подключение прошло успешно и добавляем свой файл (проверяем права на запись):
```
[root@nfsc vagrant]# ls /mnt/upload/
test_file_from_server
[root@nfsc vagrant]# touch /mnt/upload/test_file_from_client
```


Смотрим результат на стороне сервера:
```
[root@nfss vagrant]# ls -l /mnt/share/upload/
итого 0
-rw-r--r-- 1 nobody nobody 0 авг  5 22:04 test_file_from_client
-rwxrwxrwx 1 nobody nobody 0 авг  5 21:39 test_file_from_server
```


Создаём службу systemd для монтирования каталога при запуске системы:
```
[root@nfsc vagrant]# cat << EOF > /lib/systemd/system/nfs-shared.service
> [Unit]
> Description=Mount NFS share
> Requires=network-online.target
> After=network-online.target
> 
> [Service]
> Type=oneshot
> RemainAfterExit=true
> ExecStart=/bin/mount 192.168.56.10:/mnt/share/ /mnt -o fsc,hard
> ExecStop=/bin/umount /mnt/shared
> TimeoutStopSec=5
> 
> [Install]
> WantedBy=multi-user.target
> EOF

[root@nfsc vagrant]# systemctl daemon-reload 
[root@nfsc vagrant]# systemctl enable nfs-shared.service

```


Перезагружаемся и проверям что всё сработало успешно:
```
[root@nfsc vagrant]# reboot
[root@nfsc vagrant]# Connection to 127.0.0.1 closed by remote host.

seafores@echips-pc:~/VM/HW7$ vagrant ssh nfsc
Last login: Mon Aug  5 22:15:54 2024 from 10.0.2.2
[vagrant@nfsc ~]$ ls -l /mnt/upload/
итого 0
-rw-r--r-- 1 nobody nobody 0 авг  5 22:04 test_file_from_client
-rwxrwxrwx 1 nobody nobody 0 авг  5 21:39 test_file_from_server
```