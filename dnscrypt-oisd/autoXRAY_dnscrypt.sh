#!/bin/bash

# Цвета для вывода
GRN='\033[1;32m'
RED='\033[1;31m'
YEL='\033[1;33m'
CYN='\033[1;36m'
NC='\033[0m'

DNSCRYPT_CONF_DIR="/etc/dnscrypt-proxy"
DNSCRYPT_BIN="/usr/local/bin/dnscrypt-proxy"
DNSCRYPT_LOG_DIR="/var/log/dnscrypt-proxy"
BLOCKLIST_NSFW="$DNSCRYPT_CONF_DIR/blocked-nsfw.txt"
BLOCKLIST_SMALL="$DNSCRYPT_CONF_DIR/blocked-small.txt"
BLOCKLIST_MERGED="$DNSCRYPT_CONF_DIR/blocked-nsfw-small-ads.txt"

echo -e "${GRN}=== autoXRAY + dnscrypt-proxy installer ===${NC}"

[[ $EUID -eq 0 ]] || { echo -e "${RED}❌ Скрипту нужны root права${NC}"; exit 1; }

# ── Флаг -default: возврат к системному DNS ───────────────────────────────────
if [[ "$1" == "-default" ]]; then
    echo -e "${YEL}Режим -default: отключаем dnscrypt-proxy, восстанавливаем DNS...${NC}"

    systemctl stop dnscrypt-proxy 2>/dev/null
    systemctl disable dnscrypt-proxy 2>/dev/null
    echo -e "${GRN}✅ dnscrypt-proxy остановлен и отключён из автозапуска${NC}"

    chattr -i /etc/resolv.conf 2>/dev/null
    cat > /etc/resolv.conf << EOF
nameserver 1.1.1.1
nameserver 9.9.9.9
EOF
    echo -e "${GRN}✅ resolv.conf → 1.1.1.1 / 9.9.9.9 (без chattr)${NC}"

    echo -e "\n${YEL}Проверка резолвинга:${NC}"
    RESULT=$(dig +short +time=5 google.com 2>&1)
    if [ -n "$RESULT" ]; then
        echo -e "google.com: ${GRN}OK ($RESULT)${NC}"
    else
        echo -e "google.com: ${RED}FAIL${NC}"
    fi

    echo -e "\n${CYN}DNS сброшен на дефолт. dnscrypt-proxy установлен но не активен.${NC}"
    echo -e "${CYN}Для повторного включения запустите скрипт без флагов.${NC}"
    exit 0
fi

# ── 1. Определяем архитектуру ──────────────────────────────────────────────────
ARCH=$(uname -m)
case "$ARCH" in
    x86_64)  ARCH_NAME="x86_64" ;;
    aarch64) ARCH_NAME="arm64" ;;
    armv7l)  ARCH_NAME="arm" ;;
    *)
        echo -e "${RED}❌ Неподдерживаемая архитектура: $ARCH${NC}"
        exit 1
        ;;
esac
echo -e "${GRN}Архитектура: $ARCH_NAME${NC}"

# ── 2. Установка зависимостей ──────────────────────────────────────────────────
echo -e "${YEL}Установка необходимых пакетов...${NC}"
apt-get update -qq && apt-get install -y curl tar dnsutils

# ── 3. Директория логов и конфигов ────────────────────────────────────────────
mkdir -p "$DNSCRYPT_LOG_DIR"
mkdir -p "$DNSCRYPT_CONF_DIR"

# ── 4. Определяем последнюю версию ───────────────────────────────────────────
echo -e "${YEL}Получение последней версии dnscrypt-proxy с GitHub...${NC}"

LATEST_URL="https://api.github.com/repos/DNSCrypt/dnscrypt-proxy/releases/latest"
DOWNLOAD_URL=$(curl -sL "$LATEST_URL" \
    | grep "browser_download_url" \
    | grep "linux_${ARCH_NAME}-" \
    | grep -v "\.minisig" \
    | head -1 \
    | cut -d'"' -f4)

if [ -z "$DOWNLOAD_URL" ]; then
    echo -e "${RED}❌ Не удалось получить URL для скачивания (arch: $ARCH_NAME)${NC}"
    exit 1
fi

LATEST_VERSION=$(echo "$DOWNLOAD_URL" | grep -oP 'download/\K[^/]+')
INSTALLED_VERSION=$("$DNSCRYPT_BIN" --version 2>/dev/null || echo "none")

if [ "$INSTALLED_VERSION" = "$LATEST_VERSION" ]; then
    echo -e "${GRN}✅ dnscrypt-proxy $INSTALLED_VERSION уже установлен, пропускаем скачивание${NC}"
else
    echo -e "${YEL}Установлена: ${INSTALLED_VERSION} → Новая: ${LATEST_VERSION}${NC}"
    TARBALL=$(basename "$DOWNLOAD_URL")
    TMP_DIR=$(mktemp -d)

    curl -fsSL "$DOWNLOAD_URL" -o "$TMP_DIR/$TARBALL"
    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ Ошибка скачивания dnscrypt-proxy${NC}"
        rm -rf "$TMP_DIR"
        exit 1
    fi

    tar -xzf "$TMP_DIR/$TARBALL" -C "$TMP_DIR"
    EXTRACTED_BIN=$(find "$TMP_DIR" -name "dnscrypt-proxy" -type f | head -n1)
    if [ -z "$EXTRACTED_BIN" ]; then
        echo -e "${RED}❌ Не найден бинарник dnscrypt-proxy в архиве${NC}"
        rm -rf "$TMP_DIR"
        exit 1
    fi

    # Останавливаем сервис только когда нужно заменить бинарник
    systemctl stop dnscrypt-proxy 2>/dev/null
    systemctl disable dnscrypt-proxy.socket 2>/dev/null
    systemctl stop dnscrypt-proxy.socket 2>/dev/null

    cp "$EXTRACTED_BIN" "$DNSCRYPT_BIN"
    chmod +x "$DNSCRYPT_BIN"
    rm -rf "$TMP_DIR"
    echo -e "${GRN}✅ dnscrypt-proxy $LATEST_VERSION установлен в $DNSCRYPT_BIN${NC}"
fi

# ── 5. Скачивание списков блокировок и мёрдж ──────────────────────────────────
# ВАЖНО: скачиваем ДО остановки сервиса, чтобы не ломать DNS
echo -e "${YEL}Скачивание списков блокировок oisd...${NC}"

curl -fsSL "https://nsfw.oisd.nl/domainswild" -o "$BLOCKLIST_NSFW"
if [ $? -eq 0 ]; then
    echo -e "${GRN}✅ blocked-nsfw.txt: $(wc -l < "$BLOCKLIST_NSFW") строк${NC}"
else
    echo -e "${RED}❌ Ошибка скачивания nsfw.oisd.nl${NC}"
    exit 1
fi

curl -fsSL "https://small.oisd.nl/domainswild" -o "$BLOCKLIST_SMALL"
if [ $? -eq 0 ]; then
    echo -e "${GRN}✅ blocked-small.txt: $(wc -l < "$BLOCKLIST_SMALL") строк${NC}"
else
    echo -e "${RED}❌ Ошибка скачивания small.oisd.nl${NC}"
    exit 1
fi

cat "$BLOCKLIST_NSFW" "$BLOCKLIST_SMALL" | grep -v '^# ' | awk '!seen[$0]++' > "$BLOCKLIST_MERGED"
echo -e "${GRN}✅ blocked-nsfw-small-ads.txt (merged): $(wc -l < "$BLOCKLIST_MERGED") уникальных строк${NC}"

# ── 6. Конфиг ─────────────────────────────────────────────────────────────────
cat > "$DNSCRYPT_CONF_DIR/dnscrypt-proxy.toml" << EOF
# autoXRAY dnscrypt-proxy config

listen_addresses = ['127.0.0.1:53', '[::1]:53']

max_clients = 250
ipv4_servers = true
ipv6_servers = false
dnscrypt_servers = true
doh_servers = true
require_dnssec = false
require_nolog = true
require_nofilter = true

cache = true
cache_size = 8192
cache_min_ttl = 2400
cache_max_ttl = 86400
cache_neg_min_ttl = 60
cache_neg_max_ttl = 300

log_files_max_size = 20
log_files_max_age = 7
log_files_max_backups = 3

log_level = 0
log_file = '$DNSCRYPT_LOG_DIR/dnscrypt-proxy.log'

[sources]
  [sources.public-resolvers]
  urls = ['https://raw.githubusercontent.com/DNSCrypt/dnscrypt-resolvers/master/v3/public-resolvers.md', 'https://download.dnscrypt.info/resolvers-list/v3/public-resolvers.md']
  cache_file = '$DNSCRYPT_CONF_DIR/public-resolvers.md'
  minisign_key = 'RWQf6LRCGA9i53mlYecO4IzT51TGPpvWucNSCh1CBM0QTaLn73Y7GFO3'
  refresh_delay = 72

[blocked_names]
  blocked_names_file = '$BLOCKLIST_MERGED'
  log_file = '$DNSCRYPT_LOG_DIR/blocked.log'

EOF
echo -e "${GRN}✅ Конфиг создан: $DNSCRYPT_CONF_DIR/dnscrypt-proxy.toml${NC}"

# ── 7. Systemd сервис ──────────────────────────────────────────────────────────
cat > "/etc/systemd/system/dnscrypt-proxy.service" << EOF
[Unit]
Description=dnscrypt-proxy
Documentation=https://github.com/DNSCrypt/dnscrypt-proxy
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=$DNSCRYPT_BIN -config $DNSCRYPT_CONF_DIR/dnscrypt-proxy.toml
Restart=on-failure
RestartSec=5
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable dnscrypt-proxy
systemctl restart dnscrypt-proxy
sleep 3

if systemctl is-active --quiet dnscrypt-proxy; then
    echo -e "${GRN}✅ dnscrypt-proxy запущен${NC}"
else
    echo -e "${RED}❌ dnscrypt-proxy не запустился! Логи:${NC}"
    journalctl -u dnscrypt-proxy -n 20 --no-pager
    exit 1
fi

# ── 8. resolv.conf ─────────────────────────────────────────────────────────────
chattr -i /etc/resolv.conf 2>/dev/null

if systemctl is-active --quiet systemd-resolved; then
    echo -e "${YEL}Отключаем systemd-resolved...${NC}"
    systemctl stop systemd-resolved
    systemctl disable systemd-resolved
    if [ -L /etc/resolv.conf ]; then
        rm /etc/resolv.conf
    fi
fi

cat > /etc/resolv.conf << EOF
nameserver 127.0.0.1
EOF

chattr +i /etc/resolv.conf
echo -e "${GRN}✅ resolv.conf → 127.0.0.1 (chattr +i)${NC}"

# ── 9. Cron обновление списков в 6:00 ─────────────────────────────────────────
cat > "/etc/cron.d/dnscrypt-blocklists" << EOF
# autoXRAY: обновление списков блокировок dnscrypt-proxy
0 6 * * * root curl -fsSL https://nsfw.oisd.nl/domainswild -o $BLOCKLIST_NSFW && curl -fsSL https://small.oisd.nl/domainswild -o $BLOCKLIST_SMALL && cat $BLOCKLIST_NSFW $BLOCKLIST_SMALL | grep -v '^# ' | awk '!seen[\$0]++' > $BLOCKLIST_MERGED && systemctl restart dnscrypt-proxy
EOF
chmod 644 /etc/cron.d/dnscrypt-blocklists
echo -e "${GRN}✅ Cron обновление списков: ежедневно в 6:00${NC}"

# ── 10. Проверка ───────────────────────────────────────────────────────────────
echo -e "\n${YEL}=== Проверка (ждём 15 сек пока загрузятся upstream серверы) ===${NC}"
sleep 15

echo -n "Резолвинг google.com:  "
RESULT=$(dig +short +time=5 google.com @127.0.0.1 2>&1)
if [ -n "$RESULT" ]; then
    echo -e "${GRN}OK ($RESULT)${NC}"
else
    echo -e "${RED}FAIL (нет ответа)${NC}"
fi

echo -n "Блокировка pornhub.com: "
STATUS=$(dig +time=5 pornhub.com @127.0.0.1 2>&1 | grep -oP 'status: \K\w+')
BLOCKED=$(dig +short +time=5 pornhub.com @127.0.0.1 2>&1)
if [ "$STATUS" = "NXDOMAIN" ] || [ -z "$BLOCKED" ]; then
    echo -e "${GRN}BLOCKED ($STATUS)${NC}"
else
    echo -e "${YEL}WARN — ответ: $BLOCKED${NC}"
fi

# ── 11. Итог ───────────────────────────────────────────────────────────────────
SVCSTATUS=$(systemctl is-active dnscrypt-proxy)
[[ "$SVCSTATUS" == "active" ]] && SVCCOLOR="$GRN" || SVCCOLOR="$RED"

echo -e "
${CYN}╔══════════════════════════════════════════╗
║           === Итог ===                   ║
╚══════════════════════════════════════════╝${NC}
${YEL}Версия:${NC}                  ${GRN}$($DNSCRYPT_BIN --version 2>/dev/null || echo 'n/a')${NC}
${YEL}Сервис:${NC}                  ${SVCCOLOR}${SVCSTATUS}${NC}
${YEL}resolv.conf:${NC}             ${GRN}$(cat /etc/resolv.conf | tr '\n' ' ')${NC}
${YEL}blocked-nsfw.txt:${NC}        ${CYN}$(wc -l < $BLOCKLIST_NSFW) строк${NC}
${YEL}blocked-small.txt:${NC}       ${CYN}$(wc -l < $BLOCKLIST_SMALL) строк${NC}
${YEL}blocked-nsfw-small-ads:${NC}  ${CYN}$(wc -l < $BLOCKLIST_MERGED) уникальных строк${NC}
${YEL}Cron:${NC}                    ${GRN}/etc/cron.d/dnscrypt-blocklists${NC}
${YEL}Config:${NC}                  ${GRN}$DNSCRYPT_CONF_DIR/dnscrypt-proxy.toml/${NC}
${YEL}Логи:${NC}                    ${GRN}$DNSCRYPT_LOG_DIR/${NC}

${CYN}Для сброса DNS на дефолт (1.1.1.1/9.9.9.9):${NC}
  bash $(basename $0) -default
  bash <(curl -sL https://github.com/EtoDets/Auto-XRAY_Telemt/raw/main/dnscrypt-oisd/autoXRAY_dnscrypt.sh) -default
"