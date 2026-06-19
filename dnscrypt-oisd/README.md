# autoXRAY DNScrypt-oisd

Скрипт устанавливает и настраивает `dnscrypt-proxy` с блокировкой по спискам `oisd`.

Что делает:
- скачивает и устанавливает последний релиз `dnscrypt-proxy`
- настраивает `dnscrypt-proxy` и systemd-сервис
- переключает DNS на `127.0.0.1`
- скачивает и объединяет блок-листы `nsfw` и `small-ads`
- добавляет ежедневное обновление блок-листов

Запуск:
```bash
bash -c "$(curl -sL https://github.com/EtoDets/Auto-XRAY_Telemt/raw/main/dnscrypt-oisd/autoXRAY_dnscrypt.sh)"
```

Режимы запуска:

```bash
bash <(curl -sL https://github.com/EtoDets/Auto-XRAY_Telemt/raw/main/dnscrypt-oisd/autoXRAY_dnscrypt.sh) -ads-only
```
```bash
bash <(curl -sL https://github.com/EtoDets/Auto-XRAY_Telemt/raw/main/dnscrypt-oisd/autoXRAY_dnscrypt.sh) -nsfw-only
```

Что делают флаги:
- `-ads-only` — ставит только блокировку рекламы
- `-nsfw-only` — ставит только блокировку `nsfw`

---

Сброс DNS к системному варианту: `1.1.1.1` / `9.9.9.9`
```bash
bash <(curl -sL https://github.com/EtoDets/Auto-XRAY_Telemt/raw/main/dnscrypt-oisd/autoXRAY_dnscrypt.sh) -default
```
```bash
curl -sL https://github.com/EtoDets/Auto-XRAY_Telemt/raw/main/dnscrypt-oisd/autoXRAY_dnscrypt.sh | bash -s -- -default
```