# Dockerfile — скрипт мониторинга в контейнере (multi-stage)

# стадия 1: проверяем скрипт shellcheck'ом, в итоговый образ она не попадает
FROM ubuntu:22.04 AS lint
RUN apt-get update && apt-get install -y --no-install-recommends shellcheck \
    && rm -rf /var/lib/apt/lists/*
COPY script.sh /src/script.sh
RUN bash -n /src/script.sh && shellcheck /src/script.sh

# стадия 2: итоговый образ, только проверенный скрипт
FROM ubuntu:22.04
COPY --from=lint /src/script.sh /usr/local/bin/script.sh
RUN chmod +x /usr/local/bin/script.sh
WORKDIR /var/www
# в контейнере делаем 3 замера и выходим, как обычный скрипт
ENV INTERVAL=5 ITERATIONS=3
CMD ["/usr/local/bin/script.sh"]
