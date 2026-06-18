# autoXRAY DNScrypt-oisd

Скрипт устанавливает и настраивает `dnscrypt-proxy` с блокировкой по спискам `oisd`.

Что делает:
- скачивает и устанавливает последний релиз `dnscrypt-proxy`
- настраивает `dnscrypt-proxy` и systemd-сервис
- переключает DNS на `127.0.0.1`
- скачивает и объединяет блок-листы `nsfw` и `small`
- добавляет ежедневное обновление блок-листов

Запуск:
```bash
bash -c "$(curl -sL https://github.com/EtoDets/Auto-XRAY_Telemt/raw/main/dnscrypt-oisd/autoXRAY_dnscrypt.sh)"
```
---
Сброс DNS к системному варианту: `1.1.1.1` / `9.9.9.9`
```bash
bash <(curl -sL https://github.com/EtoDets/Auto-XRAY_Telemt/raw/main/dnscrypt-oisd/autoXRAY_dnscrypt.sh) -default
```

```bash
curl -sL https://github.com/EtoDets/Auto-XRAY_Telemt/raw/main/dnscrypt-oisd/autoXRAY_dnscrypt.sh | bash -s -- -default
```