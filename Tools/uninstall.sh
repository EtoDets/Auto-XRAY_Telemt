#!/bin/bash

# Цвета
GRN='\033[1;32m'
RED='\033[1;31m'
YEL='\033[1;33m'
CYN='\033[1;36m'
NC='\033[0m'

[[ $EUID -eq 0 ]] || { echo -e "${RED}❌ Скрипту нужны root права${NC}"; exit 1; }

DOMAIN=$1

# ─────────────────────────────────────────────
# ФУНКЦИИ УДАЛЕНИЯ
# ─────────────────────────────────────────────

stop_and_remove_xray() {
    echo -e "${YEL}▶ Останавливаем и удаляем Xray...${NC}"
    systemctl stop xray 2>/dev/null
    systemctl disable xray 2>/dev/null
    bash -c "$(curl -sL https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ remove 2>/dev/null

    # На случай если install-release.sh не отработал
    rm -f /usr/local/bin/xray
    rm -f /etc/systemd/system/xray.service
    rm -f /etc/systemd/system/xray@.service
    rm -rf /usr/local/etc/xray/
    rm -rf /var/log/xray/
    rm -rf /var/lib/xray/
    rm -rf /usr/local/share/xray/

    systemctl daemon-reload
    echo -e "${GRN}✅ Xray удалён${NC}"
}

remove_warp() {
    echo -e "${YEL}▶ Удаляем WARP-cli...${NC}"
    warp-cli disconnect 2>/dev/null
    systemctl stop warp-svc 2>/dev/null
    systemctl disable warp-svc 2>/dev/null
    apt-get remove --purge cloudflare-warp -y 2>/dev/null
    rm -rf /var/lib/cloudflare-warp/
    rm -f /etc/apt/sources.list.d/cloudflare-warp.list
    rm -f /usr/share/keyrings/cloudflare-warp-archive-keyring.gpg
    # Удаляем warp через fscarmen скрипт если установлен
    if command -v wgcf &>/dev/null || [ -f /etc/wireguard/wgcf-account.toml ]; then
        wg-quick down wgcf 2>/dev/null
        rm -f /etc/wireguard/wgcf* 2>/dev/null
        apt-get remove --purge wireguard wireguard-tools -y 2>/dev/null
    fi
    echo -e "${GRN}✅ WARP удалён${NC}"
}

remove_telemt() {
    echo -e "${YEL}▶ Удаляем Telemt (MTProto)...${NC}"
    systemctl stop telemt 2>/dev/null
    systemctl disable telemt 2>/dev/null
    rm -f /etc/systemd/system/telemt.service
    rm -f /usr/local/bin/telemt
    rm -rf /etc/telemt/ 2>/dev/null
    rm -rf /var/lib/telemt/ 2>/dev/null
    systemctl daemon-reload
    echo -e "${GRN}✅ Telemt удалён${NC}"
}

remove_nginx_full() {
    echo -e "${YEL}▶ Останавливаем и удаляем Nginx...${NC}"
    systemctl stop nginx 2>/dev/null
    systemctl disable nginx 2>/dev/null
    apt-get remove --purge nginx nginx-common nginx-full nginx-core -y 2>/dev/null
    rm -rf /etc/nginx/
    echo -e "${GRN}✅ Nginx удалён${NC}"
}

remove_web_dirs() {
    echo -e "${YEL}▶ Удаляем веб-директории...${NC}"
    if [ -n "$DOMAIN" ]; then
        rm -rf "/var/www/$DOMAIN"
        echo -e "   Удалено: /var/www/$DOMAIN"
    fi
    # Удаляем все кроме стандартного html
    for dir in /var/www/*/; do
        dirname=$(basename "$dir")
        if [ "$dirname" != "html" ]; then
            rm -rf "$dir"
            echo -e "   Удалено: $dir"
        fi
    done
    echo -e "${GRN}✅ Веб-директории удалены${NC}"
}

remove_certbot_full() {
    echo -e "${YEL}▶ Удаляем Certbot и сертификаты...${NC}"
    certbot delete --non-interactive 2>/dev/null || true
    apt-get remove --purge certbot python3-certbot-nginx -y 2>/dev/null
    rm -rf /etc/letsencrypt/
    rm -rf /var/lib/letsencrypt/
    rm -rf /var/log/letsencrypt/
    echo -e "${GRN}✅ Certbot и сертификаты удалены${NC}"
}

remove_sysctl_limits() {
    echo -e "${YEL}▶ Удаляем системные настройки (sysctl, limits)...${NC}"
    rm -f /etc/sysctl.d/999-autoXRAY.conf
    rm -f /etc/security/limits.d/99-autoXRAY.conf
    sysctl --system 2>/dev/null
    echo -e "${GRN}✅ Системные настройки удалены${NC}"
}

remove_symlinks_and_files() {
    echo -e "${YEL}▶ Удаляем симлинки и файлы autoXRAY...${NC}"
    rm -f ~/_nginx
    rm -f ~/_xray_log
    rm -f ~/_web_config
    rm -f ~/_xray_config
    rm -f ~/x-geodata
    rm -f ~/autoXRAY_links.txt
    rm -f /dev/shm/nginx.sock 2>/dev/null
    rm -f /dev/shm/nginxTLS.sock 2>/dev/null
    rm -f /dev/shm/nginx_h2.sock 2>/dev/null
    echo -e "${GRN}✅ Симлинки и файлы удалены${NC}"
}

# ─────────────────────────────────────────────
# РЕЖИМ 1 — ПОЛНОЕ УДАЛЕНИЕ
# ─────────────────────────────────────────────

full_uninstall() {
    echo -e "\n${RED}⚠️  ПОЛНОЕ УДАЛЕНИЕ — будет удалено ВСЁ, включая сертификаты!${NC}"
    read -p "Вы уверены? (y/N): " confirm
    [[ "$confirm" =~ ^[Yy]$ ]] || { echo -e "${YEL}Отменено.${NC}"; return; }

    stop_and_remove_xray
    remove_warp
    remove_telemt
    remove_web_dirs
    remove_certbot_full
    remove_nginx_full
    remove_sysctl_limits
    remove_symlinks_and_files

    echo -e "\n${GRN}═══════════════════════════════════════"
    echo    "✅  Полное удаление завершено"
    echo -e "═══════════════════════════════════════${NC}"
}

# ─────────────────────────────────────────────
# РЕЖИМ 2 — УДАЛЕНИЕ БЕЗ CERTBOT / СЕРТИФИКАТОВ
# ─────────────────────────────────────────────

partial_uninstall() {
    echo -e "\n${YEL}⚠️  Certbot и сертификаты Let's Encrypt будут СОХРАНЕНЫ.${NC}"
    read -p "Продолжить? (y/N): " confirm
    [[ "$confirm" =~ ^[Yy]$ ]] || { echo -e "${YEL}Отменено.${NC}"; return; }

    stop_and_remove_xray
    remove_warp
    remove_telemt
    remove_web_dirs
    remove_nginx_full
    remove_sysctl_limits
    remove_symlinks_and_files

    echo -e "\n${GRN}═══════════════════════════════════════"
    echo    "✅  Удаление завершено"
    echo    "✅  Certbot и сертификаты сохранены"
    echo -e "═══════════════════════════════════════${NC}"
    echo -e "${CYN}ℹ️  Сертификаты: /etc/letsencrypt/live/${NC}"
}

# ─────────────────────────────────────────────
# МЕНЮ
# ─────────────────────────────────────────────

clear
echo -e "${CYN}"
echo "  ╔══════════════════════════════════════════╗"
echo "  ║        autoXRAY — Удаление               ║"
echo "  ╚══════════════════════════════════════════╝"
echo -e "${NC}"

if [ -n "$DOMAIN" ]; then
    echo -e "  ${YEL}Домен: $DOMAIN${NC}\n"
else
    echo -e "  ${YEL}Домен не указан (удалит все /var/www/* кроме html)${NC}\n"
fi

echo -e "  ${GRN}1)${NC} Удалить ВСЁ (xray, warp, telemt, nginx, certbot, сертификаты)"
echo -e "  ${GRN}2)${NC} Удалить всё КРОМЕ certbot и сертификатов Let's Encrypt"
echo -e "  ${RED}0)${NC} Выход\n"

read -p "  Выберите вариант [0-2]: " choice

case "$choice" in
    1) full_uninstall ;;
    2) partial_uninstall ;;
    0) echo -e "${YEL}Выход.${NC}"; exit 0 ;;
    *) echo -e "${RED}Неверный выбор.${NC}"; exit 1 ;;
esac
