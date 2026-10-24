`script.sh` — мониторинг ресурсов: каждые `INTERVAL` секунд дописывает в `monitor.log` блок с временной меткой и выводом `free -h`, `df -h`, `uptime` (пример — в `sample_output.txt`).

## Структура

```
my-sysadmin-scripts/
├── script.sh                      # скрипт мониторинга (ДЗ1)
├── sample_output.txt              # пример вывода
├── Dockerfile                     # multi-stage: shellcheck + образ со скриптом и HTTP-сервером на 8080
├── docker-compose.yml             # то же через docker compose, лог на LVM-томе /mnt/logs
└── deploy/
    ├── nginx/my-app.conf          # reverse proxy: 80 -> 301 на 443 (TLS) -> 127.0.0.1:8080
    ├── systemd/my-app.service     # контейнер my-app как служба
    ├── systemd/raid-lab.service   # подъём RAID/LVM при загрузке
    └── raid-lab-up.sh             # подключает loop-диски, собирает md0, активирует vg_data, монтирует
```

## Схема

```
клиент -> nginx :443 (TLS) -> 127.0.0.1:8080 -> контейнер my-app (python3 http.server)
                                                   └── /var/www = /mnt/logs (LVM) <- script.sh пишет monitor.log
```

## Запуск

```bash
# контейнер
docker build -t my-script .
docker run -d -p 8080:8080 --name my-app \
  -v /mnt/logs:/var/www -v /etc/localtime:/etc/localtime:ro my-script

# nginx + TLS
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/ssl/private/my-app.key -out /etc/ssl/certs/my-app.crt -subj "/CN=my-app.local"
sudo cp deploy/nginx/my-app.conf /etc/nginx/sites-available/my-app
sudo ln -s /etc/nginx/sites-available/my-app /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx

# systemd
sudo install -m 755 deploy/raid-lab-up.sh /usr/local/sbin/raid-lab-up.sh
sudo cp deploy/systemd/*.service /etc/systemd/system/
sudo systemctl daemon-reload && sudo systemctl enable --now raid-lab my-app

curl -kI https://<адрес-машины>
```
