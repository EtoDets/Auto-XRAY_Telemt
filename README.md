# Сборка с MTProto proxy FakeTLS для ТГ


**Основной скрипт для EU-VPS**
```
bash -c "$(curl -sL https://raw.githubusercontent.com/EtoDets/Auto-XRAY_Telemt/main/autoXRAY_telemt-EU_v1.sh)" -- поддомен1.Домен.Ком
```

_Всех дольше будут работать каскадные варианты подключения._

**Для моста RU-VPS**
```
bash -c "$(curl -sL https://raw.githubusercontent.com/EtoDets/Auto-XRAY_Telemt/main/autoXRAYselfRUbrEUxhttp_telemt-RU_v2.sh)" -- поддомен2.Домен.Ком "vless://xhttp"
```

Также теперь можно использовать несколько xhttp конфигов, все они будут добавлены в мост.


 -- поддомен2.Домен.Ком "vless://xhttp1" "vless://xhttp2" "vless://xhttp3"

## Как удалить Telemt
```
bash -c "$(curl -sL https://raw.githubusercontent.com/EtoDets/Auto-XRAY_Telemt/main/Tools/uninsall_telemt.sh)"
```

**Принцип работы**

_443 Xray -> MTProto Telemt -> Сайт заглушка_

_Конфигурация_: `/etc/telemt/telemt.toml`

## Uninstall
```
bash -c "$(curl -sL https://raw.githubusercontent.com/EtoDets/Auto-XRAY_Telemt/main/Tools/uninstall.sh)"
```

---
---
---

### Автор - https://github.com/xVRVx/autoXRAY