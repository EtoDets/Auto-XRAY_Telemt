## geosite-oisd

Скрипт устанавливает и обновляет набор правил OISD для Xray в формате .dat.

### Что делает скрипт
- скачивает бинарник `domain-list-community` в `/usr/local/bin/`;
- создаёт каталог `/usr/local/share/xray/` и файл `oisd.dat`;
- генерирует вспомогательный скрипт обновления `/usr/local/share/xray/update-oisd.sh`;
- настраивает cron на обновление каждые 2 недели в 3:00;
- сразу запускает первое обновление, чтобы файл был готов к использованию.

### Для чего это нужно
Файл `oisd.dat` используется Xray для фильтрации доменов по правилам OISD (NSFW и ad-block списки). После установки можно добавить в конфиг Xray следующие правила:

```json
"ext:oisd.dat:nsfw-small"
"ext:oisd.dat:small-ads"
```

### Установка
Скрипт должен запускаться с правами root:

```bash
bash -c "$(curl -sL https://github.com/EtoDets/Auto-XRAY_Telemt/raw/main/geosite-oisd/geosite-oisd-create.sh)"
```

### Что будет создано
- `/usr/local/bin/domain-list-community` — утилита для генерации dat-файла;
- `/usr/local/share/xray/oisd.dat` — готовый файл правил;
- `/usr/local/share/xray/update-oisd.sh` — скрипт ручного обновления;
- `/var/log/update-oisd.log` — лог обновлений.

### Примечание
После установки и обновления перезапустите Xray, если он не перезапускается автоматически в процессе генерации файла.