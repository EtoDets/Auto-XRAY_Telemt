#!/bin/bash

GRN='\033[1;32m'
RED='\033[1;31m'
YEL='\033[1;33m'
NC='\033[0m'

[[ $EUID -eq 0 ]] || { echo -e "${RED}❌ нужны root права${NC}"; exit 1; }

# ============================================================
# НАСТРОЙКИ
# ============================================================
BINARY_URL="https://github.com/EtoDets/Auto-XRAY_Telemt/raw/main/geosite-oisd/domain-list-community"
BINARY_PATH="/usr/local/bin/domain-list-community"
OUTPUT_DIR="/usr/local/share/xray"
OUTPUT_NAME="oisd.dat"
UPDATE_SCRIPT="/usr/local/share/xray/update-oisd.sh"
LOG_FILE="/var/log/update-oisd.log"
DATA_DIR="/tmp/oisd-data"
# ============================================================

install_binary() {
    echo -e "${YEL}Скачиваем domain-list-community...${NC}"
    wget --timeout=60 --tries=3 -O "$BINARY_PATH" "$BINARY_URL"
    if [ $? -ne 0 ] || [ ! -s "$BINARY_PATH" ]; then
        echo -e "${RED}❌ Не удалось скачать бинарник${NC}"
        exit 1
    fi
    chmod +x "$BINARY_PATH"
    echo -e "${GRN}✅ Бинарник установлен: $BINARY_PATH${NC}"
}

create_update_script() {
    cat > "$UPDATE_SCRIPT" <<'EOF'
#!/bin/bash

GRN='\033[1;32m'
RED='\033[1;31m'
NC='\033[0m'

BINARY_PATH="/usr/local/bin/domain-list-community"
OUTPUT_DIR="/usr/local/share/xray"
OUTPUT_NAME="oisd.dat"
DATA_DIR="/tmp/oisd-data"

rm -rf "$DATA_DIR"
mkdir -p "$DATA_DIR"

echo "[$(date)] Скачиваем oisd nsfw..."
wget -q --timeout=60 --tries=3 -O "/tmp/nsfw_raw.txt" "https://nsfw-small.oisd.nl/domainswild2"
if [ $? -ne 0 ] || [ ! -s "/tmp/nsfw_raw.txt" ]; then
    echo "[$(date)] ОШИБКА: не удалось скачать nsfw список"
    exit 1
fi
grep -v '^#' /tmp/nsfw_raw.txt | grep -v '^$' | sort -u > "$DATA_DIR/nsfw-small"
rm /tmp/nsfw_raw.txt
echo "[$(date)] nsfw-small: $(wc -l < "$DATA_DIR/nsfw-small") доменов"

echo "[$(date)] Скачиваем oisd small..."
wget -q --timeout=60 --tries=3 -O "/tmp/small_raw.txt" "https://small.oisd.nl/domainswild2"
if [ $? -ne 0 ] || [ ! -s "/tmp/small_raw.txt" ]; then
    echo "[$(date)] ОШИБКА: не удалось скачать small список"
    exit 1
fi
grep -v '^#' /tmp/small_raw.txt | grep -v '^$' | sort -u > "$DATA_DIR/small-ads"
rm /tmp/small_raw.txt
echo "[$(date)] small-ads: $(wc -l < "$DATA_DIR/small-ads") доменов"

echo "[$(date)] Генерируем $OUTPUT_NAME..."
"$BINARY_PATH" -datapath "$DATA_DIR" -outputname "$OUTPUT_NAME" -outputdir "$OUTPUT_DIR"
if [ $? -ne 0 ]; then
    echo "[$(date)] ОШИБКА: генерация dat провалилась"
    exit 1
fi

echo "[$(date)] Перезапускаем xray..."
systemctl restart xray

echo "[$(date)] ✅ Готово. $OUTPUT_DIR/$OUTPUT_NAME обновлён."
EOF

    chmod +x "$UPDATE_SCRIPT"
    echo -e "${GRN}✅ Скрипт обновления создан: $UPDATE_SCRIPT${NC}"
}

setup_cron() {
    # Каждые 2 недели в воскресенье в 3:00
    CRON_LINE="0 3 */14 * * $UPDATE_SCRIPT >> $LOG_FILE 2>&1"
    ( crontab -l 2>/dev/null | grep -v "$UPDATE_SCRIPT"; echo "$CRON_LINE" ) | crontab -
    echo -e "${GRN}✅ Cron установлен: каждые 2 недели в 3:00${NC}"
}

mkdir -p "$OUTPUT_DIR"

install_binary
create_update_script
setup_cron

echo -e "${YEL}Запускаем первое обновление...${NC}"
bash "$UPDATE_SCRIPT"

echo -e "
${GRN}=== Установка завершена ===${NC}
Файл dat:       ${OUTPUT_DIR}/${OUTPUT_NAME}
Скрипт:         ${UPDATE_SCRIPT}
Лог:            ${LOG_FILE}
Cron:           каждые 2 недели в 3:00

${YEL}В xray config.json добавь:${NC}
  \"ext:oisd.dat:nsfw-small\"
  \"ext:oisd.dat:small-ads\"
"