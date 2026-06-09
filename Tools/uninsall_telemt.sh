#!/bin/bash

GRN='\033[1;32m'
RED='\033[1;31m'
YEL='\033[1;33m'
NC='\033[0m'

[[ $EUID -eq 0 ]] || { echo -e "${RED}❌ скрипту нужны root права${NC}"; exit 1; }

echo -e "${YEL}=== Удаление Telemt ===${NC}"

# Остановка и отключение сервиса
if systemctl is-active --quiet telemt; then
    systemctl stop telemt
    echo -e "${GRN}✅ Сервис telemt остановлен${NC}"
else
    echo -e "${YEL}❌  Сервис telemt не запущен${NC}"
fi

if systemctl is-enabled --quiet telemt 2>/dev/null; then
    systemctl disable telemt 2>/dev/null
    echo -e "${GRN}✅ Сервис telemt отключён из автозапуска${NC}"
fi

# Удаление unit-файла
if [ -f /etc/systemd/system/telemt.service ]; then
    rm -f /etc/systemd/system/telemt.service
    systemctl daemon-reload
    echo -e "${GRN}✅ Файл telemt.service удалён${NC}"
else
    echo -e "${YEL}❌  Файл telemt.service не найден${NC}"
fi

# Удаление бинарника
if [ -f /bin/telemt ]; then
    rm -f /bin/telemt
    echo -e "${GRN}✅ Бинарник /bin/telemt удалён${NC}"
else
    echo -e "${YEL}❌  Бинарник /bin/telemt не найден${NC}"
fi

# Удаление конфига
if [ -d /etc/telemt ]; then
    rm -rf /etc/telemt
    echo -e "${GRN}✅ Каталог /etc/telemt удалён${NC}"
else
    echo -e "${YEL}❌  Каталог /etc/telemt не найден${NC}"
fi

# Удаление пользователя и группы
if id telemt &>/dev/null; then
    userdel -r telemt 2>/dev/null
    echo -e "${GRN}✅ Пользователь telemt удалён${NC}"
else
    echo -e "${YEL}❌  Пользователь telemt не найден${NC}"
fi

if getent group telemt &>/dev/null; then
    groupdel telemt 2>/dev/null
    echo -e "${GRN}✅ Группа telemt удалена${NC}"
fi

# Удаление домашней директории пользователя
if [ -d /opt/telemt ]; then
    rm -rf /opt/telemt
    echo -e "${GRN}✅ Каталог /opt/telemt удалён${NC}"
fi

echo -e "\n${GRN}=== Telemt успешно удалён ===${NC}"