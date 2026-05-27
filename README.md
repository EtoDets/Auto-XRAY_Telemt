# Сборка с MTProto proxy FakeTLS для ТГ


**Основной скрипт для EU-VPS**
```
bash -c "$(curl -L https://raw.githubusercontent.com/EtoDets/Auto-XRAY_Telemt-Custom/refs/heads/main/autoXRAY_telemt-EU_v1.sh)" -- поддомен1.Домен.Ком
```

Всех дольше будут работать каскадные варианты подключения.

**Для моста RU-VPS**
```
bash -c "$(curl -L https://raw.githubusercontent.com/EtoDets/Auto-XRAY_Telemt-Custom/refs/heads/main/autoXRAYselfRUbrEUxhttp_telemt-RU_v2.sh)" -- поддомен2.Домен.Ком "vless://xhttp"
```

Также теперь можно использовать несколько xhttp конфигов, все они будут добавлены в мост.


 -- поддомен2.Домен.Ком "vless://xhttp1" "vless://xhttp2" "vless://xhttp3"

**Как удалить Telemt**
```
systemctl stop telemt; systemctl disable telemt; rm -f /etc/systemd/system/telemt.service /bin/telemt; systemctl daemon-reload
```

**Принцип работы**

443 XRAY -> MTP TELEMT -> сайт заглушка

Конфигурация: /etc/telemt/telemt.toml



Автор - https://github.com/xVRVx/autoXRAY
