# Создаём скрипт обновления
cat > /usr/local/share/xray/update-geodata.sh <<'SCRIPT'
#!/bin/bash
GEODATA_DIR="/usr/local/share/xray"
BASE_URL="https://github.com/runetfreedom/russia-v2ray-rules-dat/releases/latest/download"
ROSCOMVPN_geoip="https://github.com/hydraponique/roscomvpn-geoip/releases/latest/download"
ROSCOMVPN_geosite="https://github.com/hydraponique/roscomvpn-geosite/releases/latest/download"

curl -fsSL "$BASE_URL/geoip.dat" -o "$GEODATA_DIR/geoip.dat.tmp" && \
  mv "$GEODATA_DIR/geoip.dat.tmp" "$GEODATA_DIR/geoip.dat"

curl -fsSL "$BASE_URL/geosite.dat" -o "$GEODATA_DIR/geosite.dat.tmp" && \
  mv "$GEODATA_DIR/geosite.dat.tmp" "$GEODATA_DIR/geosite.dat"

# RoscomVPN GeoIP - Geosite
curl -fsSL "$ROSCOMVPN_geoip/geoip.dat" -o "$GEODATA_DIR/geoip.dat.tmp1" && \
  mv "$GEODATA_DIR/geoip.dat.tmp1" "$GEODATA_DIR/geoip_roscomvpn.dat"

curl -fsSL "$ROSCOMVPN_geosite/geosite.dat" -o "$GEODATA_DIR/geosite.dat.tmp" && \
  mv "$GEODATA_DIR/geosite.dat.tmp" "$GEODATA_DIR/geosite_roscomvpn.dat"

SCRIPT
chmod +x /usr/local/share/xray/update-geodata.sh

# Systemd service
cat > /etc/systemd/system/xray-geodata.service <<'EOF'
[Unit]
Description=Update Xray geodata from runetfreedom
After=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/local/share/xray/update-geodata.sh
EOF

# Systemd timer — раз в сутки в 3:00
cat > /etc/systemd/system/xray-geodata.timer <<'EOF'
[Unit]
Description=Daily update of Xray geodata

[Timer]
OnCalendar=*-*-* 03:00:00
RandomizedDelaySec=1h
Persistent=true

[Install]
WantedBy=timers.target
EOF

systemctl daemon-reload
systemctl enable --now xray-geodata.timer

echo -e "${GRN}Запуск обновления geodata ${NC}"
/usr/local/share/xray/update-geodata.sh

echo -e "${GRN}Перезапуск Xray ${NC}"
systemctl restart xray.service

ln -sfn /usr/local/share/xray ~/x-geodata

echo -e "${GRN}✅ Автообновление geodata настроено (ежедневно в 3:00)${NC}"
