# Домашнее задание 8 (OTUS Linux 2024 - 06)

Что нужно сделать?
- создать свой RPM (можно взять свое приложение, либо собрать к примеру Apache с определенными опциями);
- cоздать свой репозиторий и разместить там ранее собранный RPM;
- реализовать это все либо в Vagrant, либо развернуть у себя через Nginx и дать ссылку на репозиторий.


------


#### Ход выполнения работы:


Подключаемся
```
seafores@echips-pc:~/VM/HW8$ vagrant ssh
[vagrant@rpms ~]$ 
[vagrant@rpms ~]$ sudo su
```


Обновляем ОС
```
[root@rpms vagrant]# rm -rf /etc/yum.repos.d/*

[root@rpms vagrant]# cat <<\EOF > /etc/yum.repos.d/Yandex.repo 
[base]
name=CentOS-$releasever - Base
baseurl=http://mirror.yandex.ru/centos/7.9.2009/os/$basearch/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7

#released updates 
[updates]
name=CentOS-$releasever - Updates
baseurl=http://mirror.yandex.ru/centos/7.9.2009/updates/$basearch/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7

#additional packages that may be useful
[extras]
name=CentOS-$releasever - Extras
baseurl=http://mirror.yandex.ru/centos/7.9.2009/extras/$basearch/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7

#additional packages that extend functionality of existing packages
[centosplus]
name=CentOS-$releasever - Plus
baseurl=http://mirror.yandex.ru/centos/7.9.2009/centosplus/$basearch/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7
EOF

[root@rpms vagrant]# yum update -y

[root@rpms vagrant]# rm -rf /etc/yum.repos.d/CentOS-*
```


Установим необходимые утилиты:
```
[root@rpms vagrant]# yum install -y redhat-lsb-core wget rpmdevtools rpm-build createrepo yum-utils gcc
```


Будем практиковаться с редактором nano. Скачиваем последнюю версия с офф. сайта (10.08.2024):
```
[root@rpms vagrant]# wget https://www.nano-editor.org/dist/v8/nano-8.1.tar.xz
```


Распаковываем:
```
[root@rpms vagrant]# tar -xf nano-8.1.tar.xz
[root@rpms vagrant]# cd nano-8.1/

```


Создаем собственный spec файл, т.к. в исходниках готовый отсутствовал. За пример взял файл из более старой версии (релиз 999, это для удобства отслеживания):
```
[root@rpms nano-8.1]# cat <<\EOF > /home/vagrant/nano-8.1/nano.spec
%define name    nano
%define version 8.1
%define release 999

Name            : %{name}
Version         : %{version}
Release         : %{release}
Summary         : a user-friendly editor, a Pico clone with enhancements

License         : GPLv3+
Group           : Applications/Editors
URL             : https://nano-editor.org/
Source          : https://nano-editor.org/dist/latest/%{name}-%{version}.tar.gz

BuildRoot       : %{_tmppath}/%{name}-%{version}-root
BuildRequires   : autoconf, automake, gettext-devel, ncurses-devel, texinfo
Requires(post)  : info
Requires(preun) : info

%description
GNU nano is a small and friendly text editor.  It aims to emulate the
Pico text editor while also offering several enhancements.

%prep
%setup -q

%build
%configure
make

%install
make DESTDIR="%{buildroot}" install
#ln -s nano %{buildroot}/%{_bindir}/pico
rm -f %{buildroot}/%{_infodir}/dir

%post
/sbin/install-info %{_infodir}/%{name}.info %{_infodir}/dir || :

%preun
if [ $1 = 0 ] ; then
/sbin/install-info --delete %{_infodir}/%{name}.info %{_infodir}/dir || :
fi

%files
%defattr(-,root,root)
%doc AUTHORS COPYING ChangeLog INSTALL NEWS README THANKS TODO doc/faq.html doc/sample.nanorc
%{_bindir}/*
%{_docdir}/nano/*
%{_mandir}/man*/*
%{_infodir}/nano.info*
%{_datadir}/locale/*/LC_MESSAGES/nano.mo
%{_datadir}/nano/*
EOF
```


Устанавливаем необходимые зависимости:
```
[root@rpms nano-8.1]# yum-builddep nano.spec 
```


Собираем пакет
```
[root@rpms nano-8.1]# cp /home/vagrant/nano-8.1.tar.gz /root/rpmbuild/SOURCES/nano-8.1.tar.gz
[root@rpms nano-8.1]# rpmbuild -bb nano.spec
```


Проверяем:
```
[root@rpms nano-8.1]# ls -l /root/rpmbuild/RPMS/x86_64/
итого 1420
-rw-r--r--. 1 root root 788804 авг 10 16:46 nano-8.1-999.x86_64.rpm
-rw-r--r--. 1 root root 662896 авг 10 16:46 nano-debuginfo-8.1-999.x86_64.rpm
```


------


Устанавливаем nginx:
```
[root@rpms nano-8.1]# yum install epel-release
[root@rpms nano-8.1]# yum install nginx
```


Создаем папки для репозитория:
```
[root@rpms nano-8.1]# mkdir -p /usr/share/nginx/html/repo/{BUILD,BUILDROOT,RPMS,SOURCES,SPECS,SRPMS}
```


Копируем новый rpm пакет:
```
[root@rpms nano-8.1]# cp /root/rpmbuild/RPMS/x86_64/nano-8.1-999.x86_64.rpm /usr/share/nginx/html/repo/RPMS/nano-8.1-999.x86_64.rpm
```


Устанавливаем createrepo:
```
[root@rpms nano-8.1]# createrepo /usr/share/nginx/html/repo
Spawning worker 0 with 1 pkgs
Workers Finished
Saving Primary metadata
Saving file lists metadata
Saving other metadata
Generating sqlite DBs
Sqlite DBs complete

```


Добавляем локальный репозиторий
```
[root@rpms nano-8.1]# cat <<\EOF > /etc/yum.repos.d/nano_local.repo 
[nano_local]
# Имя репозитория
name=nano_local Repos
# Путь к web репозиторию
baseurl=http://127.0.0.1/repo
# Репозиторий используется
enabled=1
# Отключаем проверку ключом
gpgcheck=0
EOF
```


Включаем nginx
```
[root@rpms nano-8.1]# systemctl start nginx
```


Проверяем что репозиторий появился и видно один новый пакет:
```
[root@rpms nano-8.1]# yum repolist | grep nano
nano_local    nano_local Repos    1
```


Обновляем индексы репозитория и устанавливаем пакет через yum:
```
[root@rpms nano-8.1]# yum update

[root@rpms nano-8.1]# yum install nano
Загружены модули: fastestmirror
Loading mirror speeds from cached hostfile
 * epel: d2lzkl7pfhq30w.cloudfront.net
Разрешение зависимостей
--> Проверка сценария
---> Пакет nano.x86_64 0:8.1-999 помечен для установки
--> Проверка зависимостей окончена

Зависимости определены

...

Объем загрузки: 770 k
Объем изменений: 3.0 M
Is this ok [y/d/N]: y
Downloading packages:
nano-8.1-999.x86_64.rpm                                                                                                                                              | 770 kB  00:00:00     
Running transaction check
Running transaction test
Transaction test succeeded
Running transaction
  Установка   : nano-8.1-999.x86_64                                                                                                                                                     1/1 
  Проверка    : nano-8.1-999.x86_64                                                                                                                                                     1/1 
Установлено:
  nano.x86_64 0:8.1-999                                                                                                                                                                     
Выполнено!

```


Проверяем версию пакета:
```
[root@rpms nano-8.1]# nano -V
 GNU nano, версия 8.1
 (C) 2024 the Free Software Foundation and various contributors
 Параметры сборки: --disable-libmagic --enable-utf8
[root@rpms nano-8.1]# rpm -qa | grep nano
nano-8.1-999.x86_64
```
