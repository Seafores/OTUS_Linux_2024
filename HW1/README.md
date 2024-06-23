# Домашнее задание 1 (OTUS Linux 2024 - 06)

Описание/Пошаговая инструкция выполнения домашнего задания:
Уже настроили рабочее место? Если еще нет - используйте инструкцию по ссылке
Если возникнут вопросы, обращайтесь к студентам, преподавателям и наставникам в канал группы в Telegram.
Удачи при выполнении!

Критерии оценки:
После настройки рабочего места у вас не должно возникать проблем с функциональными требованиями для выполнения домашних работ.

------

#### Выполнена настройка рабочего места на ОС Windows 11.
Развернуты вирутальные машины (основная ALT Sisyphus): 
```
PS C:\Program Files\Oracle\VirtualBox> .\VBoxManage.exe list vms
"ALT Linux" {b682d52d-1ad5-42d8-bb23-e4804a70c405}
"Ubuntu" {76e4b188-7ba6-4460-9d62-9f4791d485d7}

PS C:\Program Files\Oracle\VirtualBox> ./VBoxManage.exe list -l runningvms
Name:                        ALT Linux
Memory size:                 8192MB
Number of CPUs:              4
Nested VT-x/AMD-V:           enabled
```

Настройка выполнна согласно инструкции, включена сквозная виртуализация, установлены необходимые пакеты:
```
[root@seafores-alt HW1]# rpm -qa | grep virtualbox-7
virtualbox-7.0.18-alt2.x86_64
```

```
[root@seafores-alt HW1]# vagrant version
Installed Version: 2.4.1
Latest Version: 2.4.1
```

```
[root@seafores-alt HW1]# ansible --version
ansible [core 2.17.0]
  config file = /etc/ansible/ansible.cfg
  configured module search path = ['/root/.ansible/plugins/modules', '/usr/share/ansible/plugins/modules']
  ansible python module location = /usr/lib/python3/site-packages/ansible
  ansible collection location = /root/.ansible/collections:/usr/share/ansible/collections
  executable location = /bin/ansible
  python version = 3.12.2 (main, Feb 29 2024, 18:26:55) [GCC 13.2.1 20240128 (ALT Sisyphus 13.2.1-alt3)] (/usr/bin/python3)
  jinja version = 3.1.4
  libyaml = True
```
