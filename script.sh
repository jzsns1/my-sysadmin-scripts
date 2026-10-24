#!/bin/bash
# Мониторинг ресурсов: раз в N секунд пишет free/df/uptime в monitor.log

INTERVAL=10          # пауза между замерами, секунд
ITERATIONS=0         # сколько замеров сделать (0 = бесконечно, до Ctrl+C)
LOG_FILE="$(dirname "$0")/monitor.log"

# проверяем, что нужные команды есть в системе
for cmd in free df uptime date; do
    if ! command -v "$cmd" > /dev/null 2>&1; then
        echo "Ошибка: команда '$cmd' не найдена" >&2
        exit 1
    fi
done

# проверяем, что в лог можно писать
if ! touch "$LOG_FILE" 2> /dev/null; then
    echo "Ошибка: нет прав на запись в $LOG_FILE" >&2
    exit 2
fi

# корректный выход по Ctrl+C / kill
trap 'echo "Мониторинг остановлен, лог: $LOG_FILE"; exit 0' INT TERM

echo "Мониторинг запущен: интервал ${INTERVAL} с, лог: $LOG_FILE"

count=0
while true; do
    {
        echo "--- $(date '+%Y-%m-%d %H:%M:%S') ---"
        free -h
        df -h
        uptime
        echo ""
    } >> "$LOG_FILE"

    count=$((count + 1))
    if [ "$ITERATIONS" -gt 0 ] && [ "$count" -ge "$ITERATIONS" ]; then
        echo "Сделано замеров: $count, лог: $LOG_FILE"
        break
    fi
    sleep "$INTERVAL"
done
