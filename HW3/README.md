# Домашнее задание 3 (OTUS Linux 2024 - 06)

Подготовить стенд на Vagrant как минимум с одним сервером. На этом сервере используя Ansible необходимо развернуть nginx со следующими условиями:
- необходимо использовать модуль yum/apt;
- конфигурационные файлы должны быть взяты из шаблона jinja2 с перемененными;
- после установки nginx должен быть в режиме enabled в systemd;
- должен быть использован notify для старта nginx после установки;
- сайт должен слушать на нестандартном порту - 8080, для этого использовать переменные в Ansible.

Критерии оценки. Статус "Принято" ставится, если:
- предоставлен Vagrantfile и готовый playbook/роль (инструкция по запуску стенда, если посчитаете необходимым);
- после запуска стенда nginx доступен на порту 8080;
- при написании playbook/роли соблюдены перечисленные в задании условия.

------

#### Ход выполнения работы:

Проверяем версию Ansible на основной системе:
```
seafores@fedora-pc:~/OTUS_Linux_2024/HW3$ ansible --version
ansible [core 2.16.8]
  config file = /etc/ansible/ansible.cfg
  configured module search path = ['/home/seafores/.ansible/plugins/modules', '/usr/share/ansible/plugins/modules']
  ansible python module location = /usr/lib/python3.12/site-packages/ansible
  ansible collection location = /home/seafores/.ansible/collections:/usr/share/ansible/collections
  executable location = /usr/bin/ansible
  python version = 3.12.4 (main, Jun  7 2024, 00:00:00) [GCC 14.1.1 20240607 (Red Hat 14.1.1-5)] (/usr/bin/python3)
  jinja version = 3.1.4
  libyaml = True
```

Устанавливаем и запускаем ВМ:
```
seafores@fedora-pc:~/OTUS_Linux_2024/HW3$ vagrant up
```

Подготавливаем inventory файл:
```
seafores@fedora-pc:~/OTUS_Linux_2024/HW3$ mkdir -p ./staging
seafores@fedora-pc:~/OTUS_Linux_2024/HW3$ echo "nginx ansible_host=127.0.0.1 ansible_port=2222 ansible_user=vagrant ansible_private_key_file=.vagrant/machines/nginx/virtualbox/private_key" > ./staging/hosts
```

Проверяем доступность ВМ используя Ansible:
```
seafores@fedora-pc:~/OTUS_Linux_2024/HW3$ ansible nginx -i staging/hosts -m ping
The authenticity of host '[127.0.0.1]:2222 ([127.0.0.1]:2222)' can't be established.
ED25519 key fingerprint is SHA256:QpSKlrqoA55C+qOgCb+Pms7Cntm/oHnwjZNryoMfZQA.
This key is not known by any other names.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
nginx | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "changed": false,
    "ping": "pong"
}
```

Скачиваем шаблон jinja2 для nginx:
```
seafores@fedora-pc:~/OTUS_Linux_2024/HW3$ wget https://gist.githubusercontent.com/lalbrekht/e76c659b1802512f7f860caefe738771/raw/f1dab76c1568db0ebc1e15f5aa9ff4ff651512ad/gistfile1.txt
gistfile1.txt        100% [==========================================================>]     266     --.-KB/s
                          [Files: 1  Bytes: 266  [406 B/s] Redirects: 0  Todo: 0  Erro]
seafores@fedora-pc:~/OTUS_Linux_2024/HW3$ mkdir -p templates
seafores@fedora-pc:~/OTUS_Linux_2024/HW3$ mv gistfile1.txt templates/nginx.conf.j2
```

Редактируем playbook:
```
seafores@fedora-pc:~/OTUS_Linux_2024/HW3$ nano nginx.yml
```

Запускаем playbook:
```
seafores@fedora-pc:~/OTUS_Linux_2024/HW3$ ansible-playbook nginx.yml -i staging/hosts
PLAY [install and configure nginx]

TASK [Gathering Facts]
ok: [nginx]

TASK [Update repositories cache and install nginx package]
changed: [nginx]

TASK [Template nginx config file to /etc/nginx/nginx.conf]
changed: [nginx]

RUNNING HANDLER [Restart nginx]
changed: [nginx]

PLAY RECAP ****************************************
nginx : ok=4    changed=3    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

Проверяем:
```
seafores@fedora-pc:~/OTUS_Linux_2024/HW3$ ansible nginx -i staging/hosts -m shell -a "curl http://192.168.11.150:8080 | grep title"
nginx | CHANGED | rc=0 >>
<title>Welcome to nginx!</title>  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100   612  100   612    0     0  85798      0 --:--:-- --:--:-- --:--:--   99k
```
