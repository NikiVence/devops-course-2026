# Конфигурация виртуальной машины devops-vm

## 1. Параметры машины

- Гипервизор: VirtualBox.
- ОС: Ubuntu Server 24.04.5 LTS.
- Оперативная память: около 2 ГБ (1.9 GiB доступно ОС).
- Процессоры: 2.
- Диск /dev/sda: 25 ГБ.
- Корневая файловая система: /dev/sda2.
- Swap: 2 ГБ.

## 2. Сетевые интерфейсы

- enp0s3: NAT, адрес 10.0.2.15/24, выход в интернет.
- enp0s8: Host-only, адрес 192.168.247.101/24,
  подключение с Windows к виртуальной машине.
- Адрес Windows в сети Host-only: 192.168.247.1.

В файл C:\Windows\System32\drivers\etc\hosts добавлена запись:

    192.168.247.101 devops.local

Проверка на Windows:

    ping -n 2 devops.local

Имя сервера задано командой:

    sudo hostnamectl set-hostname devops-vm

Запись в /etc/hosts Ubuntu:

    127.0.1.1 devops-vm.devops.local devops-vm

Команда hostname -f выводит devops-vm.devops.local.

## 3. Правило проброса портов

В выполненной конфигурации подключение осуществляется напрямую
через Host-only: 192.168.247.101:2222.

Проброс NAT для этого подключения не используется.
Наличие отдельных правил проброса в VirtualBox не проверялось.

## 4. Учётные записи

Работа выполняется пользователем devops, UID 1000.
Пользователь входит в группу sudo.

Для SSH используется ключ Ed25519.
Закрытый ключ хранится только на Windows:

    %USERPROFILE%\.ssh\id_ed25519_devops_2026

Открытая часть добавлена на сервер в:

    /home/devops/.ssh/authorized_keys

Права доступа:

    chmod 700 ~/.ssh
    chmod 600 ~/.ssh/authorized_keys

Подключение из PowerShell:

    ssh -p 2222 -o IdentitiesOnly=yes -i "$env:USERPROFILE\.ssh\id_ed25519_devops_2026" devops@devops.local

## 5. Служба SSH

Исходная конфигурация сохранена в /etc/ssh/sshd_config.backup.

Настройки /etc/ssh/sshd_config.d/99-hardening.conf:

    Port 2222
    PermitRootLogin no
    PasswordAuthentication no
    KbdInteractiveAuthentication no
    PubkeyAuthentication yes
    PermitEmptyPasswords no
    MaxAuthTries 3
    LoginGraceTime 30
    AllowUsers devops
    X11Forwarding no
    ClientAliveInterval 300
    ClientAliveCountMax 2

В /etc/ssh/sshd_config.d/50-cloud-init.conf закомментирована
строка PasswordAuthentication yes, которая имела приоритет.
Перед изменением создана копия 50-cloud-init.conf.backup.

Проверка конфигурации:

    sudo sshd -t
    sudo sshd -T

Отключена активация через сокет и включена служба:

    sudo systemctl disable --now ssh.socket
    sudo systemctl enable --now ssh.service
    sudo systemctl restart ssh

Проверка слушающего порта:

    sudo ss -tlnp | grep sshd

SSH слушает порт 2222 по IPv4 и IPv6.
Новое подключение по ключу проверено до закрытия старой сессии.
Вход root и попытка входа без ключа отклоняются.

## 6. Правила межсетевого экрана

UFW активен. Политики:
- входящие соединения: deny;
- исходящие соединения: allow.

Правила для IPv4 и IPv6:
- 2222/tcp: LIMIT IN;
- 80/tcp: ALLOW IN;
- 443/tcp: ALLOW IN.

Разрешающие правила созданы до включения UFW.
Итоговую конфигурацию можно получить командами:

    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    sudo ufw limit 2222/tcp comment 'SSH rate-limited'
    sudo ufw allow 80/tcp comment 'HTTP'
    sudo ufw allow 443/tcp comment 'HTTPS'
    sudo ufw logging medium
    sudo ufw enable

Проверка:

    sudo ufw status verbose

Запрос с Windows к порту 8080 завершился тайм-аутом.
В /var/log/ufw.log зафиксированы UFW BLOCK:
SRC=192.168.247.1, DST=192.168.247.101, PROTO=TCP, DPT=8080.

Новое SSH-подключение после включения UFW успешно.

## 7. Снимки состояния

Даты приведены по интерфейсу VirtualBox:

- 02-keys-configured — 12.11.2026 01:45:
  настроен и проверен вход по ключу.
- 03-ssh-hardened — 12.11.2026 02:10:
  применены ограничения SSH и порт 2222.

Снимок 01-clean-install не создавался.
Восстановление из него не выполнялось.

Настройки UFW, локального имени и скрипт аудита добавлены
после создания 03-ssh-hardened и находятся в текущем состоянии.

## Проверка конфигурации

Скрипт: scripts/audit.sh.

Запуск из корня репозитория:

    ./scripts/audit.sh
    echo $?

На правильной конфигурации: 6 успешных проверок, код 0.

При временной замене MaxAuthTries 3 на MaxAuthTries 10:
5 успешных проверок, 1 ошибка, код 1.

После возврата MaxAuthTries 3: 6 успешных проверок, код 0.
Во время этого испытания служба SSH не перезапускалась:
скрипт проверяет параметры файлов через sshd -T.

## 8. Веб-сервер

Пакеты: nginx и rsync. Nginx включён в автозапуск.
Конфигурация: /etc/nginx/sites-available/devops-site.
В sites-enabled создана ссылка на неё, ссылка default удалена.

Каталог сайта: /var/www/devops-site, владелец devops:devops.
Права каталогов 755, файлов 644. Страницы: index.html и 404.html.
HTTP на порту 80 перенаправляется кодом 301 на HTTPS.
HTTPS работает на порту 443, имя devops.local, TLS 1.2 и 1.3.
Для неизвестных путей возвращается собственная страница с кодом 404.

Сертификат: /etc/ssl/certs/devops.crt, root:root, права 644.
Ключ: /etc/ssl/private/devops.key, root:root, права 600.
Самоподписанный сертификат создан на 365 дней командой:

    sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/ssl/private/devops.key -out /etc/ssl/certs/devops.crt -subj "/CN=devops.local" -addext "subjectAltName=DNS:devops.local"

Применение конфигурации:

    sudo nginx -t && sudo systemctl reload nginx

Журналы:
- /var/log/nginx/devops-site.access.log
- /var/log/nginx/devops-site.error.log

Рабочая копия для доставки находится в Kali WSL2:
~/devops-course-2026. Сервер работает в Ubuntu VirtualBox.
В Kali настроен SSH-псевдоним devops для 192.168.247.101:2222.
Доверенный сертификат скопирован в ~/devops.crt.

Скрипт scripts/deploy.sh выполняет rsync с --delete и
--chmod=D755,F644, затем проверяет HTTPS через --cacert.
Адрес сервера для проверки задан через --resolve.
Перед доставкой проверяются наличие index.html и чистота Git.
Режим --dry-run не изменяет сервер.
Для SSH используется BatchMode=yes, интерактивный пароль не запрашивается.

Проверены все пять сценариев деплоя: dry-run и штатная доставка
возвращают 0; незакоммиченные изменения, остановленный Nginx
и отсутствие index.html возвращают 1.

При правах каталога 755 и 711 страница доступна, при 750 и 744
возвращается 403. При правах файла 600 возвращается 403.
При правах файла 666 пользователь www-data смог изменить страницу.
Штатный деплой восстановил содержимое и права 644.

Аудит дополнен проверками службы Nginx, синтаксиса конфигурации,
срока сертификата и прав сайта и ключа. Порог срока по умолчанию
составляет 2592000 секунд (30 дней). Для отрицательного испытания
используется переменная CERT_MIN_SECONDS.
