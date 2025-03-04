#!/bin/bash

source config.conf

GREEN="\033[0;32m"
RED="\033[0;31m"
NC="\033[0m"


log () {
    datatime="$(date '+%Y-%m-%d %H:%M:%S')"
    if [ -n "$2" ]; then
        if [ $2 -eq 0 ]; then
            echo "${datatime} - $1" >> "$LOGFILE"
            echo -e "[-] ${RED}$1 ${NC}"
        elif [ $2 -eq 1 ]; then
            echo "${datatime} - $1" >> "$LOGFILE"
            echo -e "[+] ${GREEN}$1 ${NC}"
        elif [ $2 -eq 2 ]; then
            echo "${datatime} - ---| $1 |---" >> "$LOGFILE"
            echo -e "\n---| $1 |---\n"
        fi
    else
        echo "${datatime} - $1" >> "$LOGFILE"
    fi
}

log "Проверка интернета" 2

if ping -c 4 "$INTERNET_CHECK_HOST" > /dev/null 2>&1; then
    echo "РАБОТАЕТ"
fi

log "Проверка DNS" 2

if nslookup google.com > /dev/null 2>&1; then
    log "ДНС РАБОТАЕТ" 1
else
    log "DNS NOT WORK " 0
fi

log "Проверка целостности файла" 2

if dd if=system_check.log of=/dev/null bs=1M 2>/dev/null; then
    log "Файл в полном порядке" 1
else 
    log "Найдены проблемы в файле" 0
fi

log "Проверка свободного места" 2

df -h | grep '^/dev/' | awk '{print $1, $2, $3}' | while read disk total size; do
    echo "${disk} ${total} ${size}"
done


log "CPU" 2

cpu_load=$(top -bn1 | grep 'Cpu(s)' | awk '{print 100 - $8}' | tr ',' '.')
log "Загрузка CPU - ${cpu_load}%"
echo -e "CPU - ${GREEN}${cpu_load}%${NC}"


log "Проверка ОЗУ"

total=$(free -h | grep 'Mem' | awk '{print $2}')
used=$(free -h | grep 'Mem' | awk '{print $3}')
free=$(free -h | grep 'Mem' | awk '{print $4}')

echo -e "Всего: ${GREEN}${total}${NC}\nЗанято: ${used}\nСвободно: ${free}\n"
log "Всего: ${total} - Занято: ${used} - Свободно: ${free}"

log "Проверка MySQL" 2

if mysqladmin ping -u "$DB_USER" -p"$DB_PASSWORD" > /dev/null 2>&1; then
    echo "SQL работает"
fi


log "Проверка служб" 2

services=(httpd ssh mysql)
for service in "${services[@]}"; do
    if systemctl is-active $service > /dev/null 2>&1; then
        log "${service} работает " 1
    else 
        log "${service} не работает " 0
    fi
done

log "Проверка PostgreSQL" 2

if command -v postgresql > /dev/null 2>&1; then
    echo "POSTGRE WORK"
    if postgresql -u user > /dev/null 2>&1; then
        echo "POSTGRE ACTIVE"
    else
        echo "POSTGRE NO ACTIVE!!!"
    fi
else
    echo "POSTGRE NO WORK!!!!!"
fi