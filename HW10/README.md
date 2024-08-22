# Домашнее задание 10 (OTUS Linux 2024 - 06)

Выполнить следующие задания и подготовить развёртывание результата выполнения с использованием Vagrant и Vagrant shell provisioner (или Ansible, на Ваше усмотрение):

- Написать service, который будет раз в 30 секунд мониторить лог на предмет наличия ключевого слова (файл лога и ключевое слово должны задаваться в /etc/default).
- Установить spawn-fcgi и создать unit-файл (spawn-fcgi.sevice) с помощью переделки init-скрипта (https://gist.github.com/cea2k/1318020).
- Доработать unit-файл Nginx (nginx.service) для запуска нескольких инстансов сервера с разными конфигурационными файлами одновременно.


------

#### Ход выполнения работы:

Основной код встроен в Vagrant shell provisioner.

Проверяем результат после выполнения vagrant up:


```
seafores@echips-pc:~/VM/HW10$ vagrant ssh
[vagrant@systemd ~]$ sudo journalctl | grep Seafores
авг 22 19:54:10 systemd root[8818]: Чт 22 авг 2024 19:54:10 MSK: I found word "Sockets", Seafores!
авг 22 19:54:46 systemd root[8899]: Чт 22 авг 2024 19:54:46 MSK: I found word "Sockets", Seafores!
авг 22 19:55:34 systemd root[8984]: Чт 22 авг 2024 19:55:34 MSK: I found word "Sockets", Seafores!
```


```
[vagrant@systemd ~]$ sudo systemctl status spawn-fcgi.service
● spawn-fcgi.service - Spawn-fcgi startup service by Otus
     Loaded: loaded (/etc/systemd/system/spawn-fcgi.service; disabled; vendor preset: disabled)
     Active: active (running) since Thu 2024-08-22 19:54:10 MSK; 1min 48s ago
   Main PID: 8820 (php-cgi-8.2)
      Tasks: 33 (limit: 2366)
     Memory: 64.0M
        CPU: 634ms
     CGroup: /system.slice/spawn-fcgi.service
             ├─8820 /usr/bin/php-cgi-8.2
             ├─8859 /usr/bin/php-cgi-8.2
             ├─8860 /usr/bin/php-cgi-8.2
             ├─8861 /usr/bin/php-cgi-8.2
             ├─8862 /usr/bin/php-cgi-8.2
             ├─8863 /usr/bin/php-cgi-8.2
             ├─8864 /usr/bin/php-cgi-8.2
             ├─8865 /usr/bin/php-cgi-8.2
             ├─8866 /usr/bin/php-cgi-8.2
             ├─8867 /usr/bin/php-cgi-8.2
             ├─8868 /usr/bin/php-cgi-8.2
             ├─8869 /usr/bin/php-cgi-8.2
             ├─8870 /usr/bin/php-cgi-8.2
             ├─8871 /usr/bin/php-cgi-8.2
             ├─8872 /usr/bin/php-cgi-8.2
             ├─8873 /usr/bin/php-cgi-8.2
             ├─8874 /usr/bin/php-cgi-8.2
             ├─8875 /usr/bin/php-cgi-8.2
             ├─8876 /usr/bin/php-cgi-8.2
             ├─8877 /usr/bin/php-cgi-8.2
             ├─8878 /usr/bin/php-cgi-8.2
             ├─8879 /usr/bin/php-cgi-8.2
             ├─8880 /usr/bin/php-cgi-8.2
             ├─8881 /usr/bin/php-cgi-8.2
             ├─8882 /usr/bin/php-cgi-8.2
             ├─8883 /usr/bin/php-cgi-8.2
             ├─8884 /usr/bin/php-cgi-8.2
             ├─8885 /usr/bin/php-cgi-8.2
             ├─8886 /usr/bin/php-cgi-8.2
             ├─8887 /usr/bin/php-cgi-8.2
             ├─8888 /usr/bin/php-cgi-8.2
             ├─8889 /usr/bin/php-cgi-8.2
             └─8890 /usr/bin/php-cgi-8.2

авг 22 19:54:10 systemd systemd[1]: Started Spawn-fcgi startup service by Otus.
```


```
[vagrant@systemd ~]$ sudo ss -tlpn | grep nginx
LISTEN 0      511          0.0.0.0:9001      0.0.0.0:*    users:(("nginx",pid=8835,fd=6),("nginx",pid=8834,fd=6),("nginx",pid=8833,fd=6),("nginx",pid=8832,fd=6),("nginx",pid=8831,fd=6),("nginx",pid=8830,fd=6),("nginx",pid=8829,fd=6),("nginx",pid=8828,fd=6),("nginx",pid=8827,fd=6),("nginx",pid=8826,fd=6),("nginx",pid=8825,fd=6),("nginx",pid=8824,fd=6))                        
LISTEN 0      511          0.0.0.0:9002      0.0.0.0:*    users:(("nginx",pid=8858,fd=6),("nginx",pid=8857,fd=6),("nginx",pid=8856,fd=6),("nginx",pid=8855,fd=6),("nginx",pid=8854,fd=6),("nginx",pid=8853,fd=6),("nginx",pid=8852,fd=6),("nginx",pid=8851,fd=6),("nginx",pid=8850,fd=6),("nginx",pid=8849,fd=6),("nginx",pid=8848,fd=6),("nginx",pid=8847,fd=6),("nginx",pid=8846,fd=6))
```