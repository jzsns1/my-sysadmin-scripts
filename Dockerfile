# Dockerfile — скрипт мониторинга + HTTP-сервер для отдачи monitor.log (multi-stage)

# стадия 1: проверяем скрипт shellcheck'ом, в итоговый образ она не попадает
FROM ubuntu:22.04 AS lint
RUN apt-get update && apt-get install -y --no-install-recommends shellcheck \
    && rm -rf /var/lib/apt/lists/*
COPY script.sh /src/script.sh
RUN bash -n /src/script.sh && shellcheck /src/script.sh

# стадия 2: итоговый образ — скрипт пишет monitor.log в /var/www, python отдаёт его на 8080
FROM ubuntu:22.04
RUN apt-get update && apt-get install -y --no-install-recommends python3 \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /var/www
COPY --from=lint /src/script.sh /usr/local/bin/script.sh
RUN chmod +x /usr/local/bin/script.sh
EXPOSE 8080
# python (PID 1 в контейнере) игнорирует SIGTERM, а на SIGINT завершается сразу и с кодом 0
STOPSIGNAL SIGINT
CMD ["/bin/bash", "-c", "/usr/local/bin/script.sh & exec python3 -m http.server 8080"]
