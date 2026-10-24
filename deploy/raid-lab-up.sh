#!/bin/bash
# Поднимает RAID 1 (/mnt/raid) и LVM (/mnt/logs) на loop-устройствах после перезагрузки.
# loop-устройства не переживают ребут, поэтому файлы-диски подключаются заново.
set -e

LAB=/mnt/raid-lab

# подключаем файл как loop-устройство, если ещё не подключён, и печатаем имя устройства
attach() {
    local dev
    dev=$(losetup -j "$1" | cut -d: -f1)
    [ -n "$dev" ] || dev=$(losetup -fP --show "$1")
    echo "$dev"
}

LOOP1=$(attach "$LAB/disk1.img")
LOOP2=$(attach "$LAB/disk2.img")
LOOP3=$(attach "$LAB/disk3.img")
echo "loop: $LOOP1 $LOOP2 $LOOP3"

# RAID 1: собираем массив, если udev не собрал его сам
grep -q "^md0 " /proc/mdstat || mdadm --assemble /dev/md0 "$LOOP1" "$LOOP2"

# LVM: активируем группу томов на третьем диске
vgchange -ay vg_data

mkdir -p /mnt/raid /mnt/logs
mountpoint -q /mnt/raid || mount /dev/md0 /mnt/raid
mountpoint -q /mnt/logs || mount /dev/vg_data/lv_logs /mnt/logs
echo "смонтировано: /mnt/raid, /mnt/logs"
