# autoXRAY DNScrypt-oisd

Набор скриптов для установки `dnscrypt-proxy` и включения блокировки доменов через списки `oisd`/`1Hosts`.

## Какой скрипт использовать

### 1) `autoXRAY_dnscrypt.sh`
Базовая версия. Ставит `dnscrypt-proxy`, включает DNS на `127.0.0.1`, скачивает списки и запускает блокировку.

Запуск:
```bash
bash -c "$(curl -sL https://github.com/EtoDets/Auto-XRAY_Telemt/raw/main/dnscrypt-oisd/autoXRAY_dnscrypt.sh)"
```

Поддерживаемые флаги:
```bash
bash <(curl -sL https://github.com/EtoDets/Auto-XRAY_Telemt/raw/main/dnscrypt-oisd/autoXRAY_dnscrypt.sh) -ads-only
bash <(curl -sL https://github.com/EtoDets/Auto-XRAY_Telemt/raw/main/dnscrypt-oisd/autoXRAY_dnscrypt.sh) -nsfw-only
bash <(curl -sL https://github.com/EtoDets/Auto-XRAY_Telemt/raw/main/dnscrypt-oisd/autoXRAY_dnscrypt.sh) -default
```

Что делают флаги:
- `-ads-only` — блокировать только рекламу
- `-nsfw-only` — блокировать только `nsfw`-список
- без флага — включить и рекламу, и `nsfw`
- `-default` — отключить `dnscrypt-proxy` и вернуть DNS к `1.1.1.1 / 9.9.9.9`

Какие списки используются:
- `https://nsfw.oisd.nl/domainswild` — список `nsfw`
- `https://big.oisd.nl/domainswild` — список рекламы/трекинга `oisd`

Скрипт объединяет выбранные списки в один итоговый `blocked-full-merger.txt` и подставляет его в `dnscrypt-proxy`.

Сброс DNS:
```bash
bash <(curl -sL https://github.com/EtoDets/Auto-XRAY_Telemt/raw/main/dnscrypt-oisd/autoXRAY_dnscrypt.sh) -default
```
```bash
curl -sL https://github.com/EtoDets/Auto-XRAY_Telemt/raw/main/dnscrypt-oisd/autoXRAY_dnscrypt.sh | bash -s -- -default
```

---

### 2) `autoXRAY_dnscrypt_v2.sh`
Более полный вариант. Помимо установки добавляет автоматическое обновление блок-листов, проверку сервисов, и создаёт cron-обновление списков.

Запуск:
```bash
bash <(curl -sL https://github.com/EtoDets/Auto-XRAY_Telemt/raw/main/dnscrypt-oisd/autoXRAY_dnscrypt_v2.sh)
```

Поддерживаемые флаги:
```bash
bash <(curl -sL https://github.com/EtoDets/Auto-XRAY_Telemt/raw/main/dnscrypt-oisd/autoXRAY_dnscrypt_v2.sh) -ads-only
bash <(curl -sL https://github.com/EtoDets/Auto-XRAY_Telemt/raw/main/dnscrypt-oisd/autoXRAY_dnscrypt_v2.sh) -nsfw-only
bash <(curl -sL https://github.com/EtoDets/Auto-XRAY_Telemt/raw/main/dnscrypt-oisd/autoXRAY_dnscrypt_v2.sh) -default
```

Что делают флаги:
- `-ads-only` — блокировать только реклама/ads-списки
- `-nsfw-only` — блокировать только `nsfw`
- без флага — блокировать и `nsfw`, и рекламу
- `-default` — отключить `dnscrypt-proxy` и вернуть DNS на `1.1.1.1 / 9.9.9.9`

Какие списки используются:
- `https://nsfw.oisd.nl/domainswild` — список `nsfw`
- `https://big.oisd.nl/domainswild` — список `oisd` для рекламы
- `https://raw.githubusercontent.com/badmojr/1Hosts/master/Lite/wildcards.txt` — дополнительный список `1Hosts Lite` для рекламы и доменов с вредоносной/всплывающей активностью

Итоговый файл:
- `blocked-full-merger.txt` — объединённый список после дедупликации и фильтрации комментариев

v2 дополнительно:
- создаёт `update-blocklists.sh`
- добавляет ежедневный cron-обновляющий список в 06:00
- перекладывает DNS на `127.0.0.1`
- отключает `systemd-resolved` при необходимости

Сброс DNS:
```bash
bash <(curl -sL https://github.com/EtoDets/Auto-XRAY_Telemt/raw/main/dnscrypt-oisd/autoXRAY_dnscrypt_v2.sh) -default
```
```bash
curl -sL https://github.com/EtoDets/Auto-XRAY_Telemt/raw/main/dnscrypt-oisd/autoXRAY_dnscrypt_v2.sh | bash -s -- -default
```

---

## Коротко по смыслу режимов

- `-ads-only` = только блокировка рекламы
- `-nsfw-only` = только блокировка NSFW
- без флага = оба списка
- `-default` = вернуть DNS к системному провайдеру

Скрипты используют `dnscrypt-proxy` в режиме локального DNS-сервера на `127.0.0.1:53`, поэтому после установки весь системный DNS идёт через него.