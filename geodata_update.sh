# Создаём скрипт обновления
cat > /usr/local/bin/update-xray-geodata.sh <<'SCRIPT'
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

# systemctl restart xray
SCRIPT
chmod +x /usr/local/bin/update-xray-geodata.sh

# Systemd service
cat > /etc/systemd/system/xray-geodata.service <<'EOF'
[Unit]
Description=Update Xray geodata from runetfreedom
After=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/update-xray-geodata.sh
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

ln -sfn /usr/local/bin/ ~/xray_update-geodata
ln -sfn /usr/local/share/xray ~/xray-geodata

echo -e "${GRN}✅ Автообновление geodata настроено (ежедневно в 3:00)${NC}"
