# autoXRAY dnscrypt-oisd

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