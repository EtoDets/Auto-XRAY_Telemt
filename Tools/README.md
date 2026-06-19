# traffic.sh

Скрипт показывает статистику трафика Xray через локальный API `127.0.0.1:10185` и выводит ее в удобном табличном виде. Он группирует данные по `inbound`, `outbound` и `user`, считает upload/download/total и форматирует объемы в `B`, `KiB`, `MiB`, `GiB`.

## Запуск

```bash
bash -c "$(curl -fsSL https://github.com/EtoDets/Auto-XRAY_Telemt/raw/main/Tools/traffic.sh)"
```
