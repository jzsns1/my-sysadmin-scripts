# Dockerfile — скрипт мониторинга в контейнере
FROM ubuntu:22.04
COPY script.sh /usr/local/bin/script.sh
RUN chmod +x /usr/local/bin/script.sh
WORKDIR /var/www
# в контейнере делаем 3 замера и выходим, как обычный скрипт
ENV INTERVAL=5 ITERATIONS=3
CMD ["/usr/local/bin/script.sh"]
