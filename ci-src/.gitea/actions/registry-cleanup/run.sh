#!/usr/bin/env bash
# источник: nii-energomash/automation/ci-src/.gitea/actions/registry-cleanup/run.sh
# место: .gitea/actions/registry-cleanup/run.sh

# Удаляет из реестра Gitea технические образы — версии с тегом вида sha-<7>
# старше заданного возраста. Релизные теги и latest не трогаются никогда.
# Ожидает в окружении REGISTRY, OWNER, PACKAGE, DAYS_OLD, HOURS_OLD, SHOW_ONLY,
# GT_TOKEN — их задаёт action.yml.
set -euo pipefail

if [ -z "$REGISTRY" ]; then
  echo 'Не задан адрес инстанса — переменная репозитория REGISTRY_HOST' >&2
  exit 1
fi

if [ -z "$OWNER" ]; then
  echo 'Не задан владелец пакетов — переменная репозитория REGISTRY_OWNER' >&2
  exit 1
fi

if ! printf '%s' "$DAYS_OLD" | grep -Eq '^[0-9]+$'; then
  echo "days-old должен быть целым неотрицательным числом, получено '$DAYS_OLD'" >&2
  exit 1
fi

if ! printf '%s' "$HOURS_OLD" | grep -Eq '^([0-9]|1[0-9]|2[0-3])$'; then
  echo "hours-old должен лежать в диапазоне 0–23, получено '$HOURS_OLD'" >&2
  exit 1
fi

if [ "$SHOW_ONLY" != 'true' ] && [ "$SHOW_ONLY" != 'false' ]; then
  echo "show-only должен быть 'true' или 'false', получено '$SHOW_ONLY'" >&2
  exit 1
fi

# Отбор делает jq: у Gitea нет CLI вроде gh со встроенным разбором ответа.
if ! command -v jq >/dev/null; then
  apt-get update -qq
  apt-get install -y -qq jq
fi

# Реестр отвечает по https с самоподписанным сертификатом. Раннер монтирует CA
# в задание и указывает на него SSL_CERT_FILE; curl эту переменную сам не
# смотрит, поэтому путь передаётся явно.
CURL_ARGS=(--fail --silent --show-error -H "Authorization: token $GT_TOKEN")
if [ -n "${SSL_CERT_FILE:-}" ] && [ -f "$SSL_CERT_FILE" ]; then
  CURL_ARGS+=(--cacert "$SSL_CERT_FILE")
fi

API="https://$REGISTRY/api/v1/packages/$OWNER"
# Смещение задаётся знаком, а не словом ago: ago в date относится только к
# последней единице, и «1 days 0 hours ago» уехало бы на сутки вперёд.
CUTOFF=$(date -d "-$DAYS_OLD days -$HOURS_OLD hours" +%s)

echo "Пакет:   $OWNER/$PACKAGE"
echo "Граница: $(date -d "@$CUTOFF" --iso-8601=seconds) (старше $DAYS_OLD д. $HOURS_OLD ч.)"
if [ "$SHOW_ONLY" = 'true' ]; then
  echo "Режим:   только показать"
else
  echo "Режим:   удаление"
fi
echo

# Список версий берётся с эндпоинта владельца: он возвращает по записи на
# версию, а q фильтрует по подстроке имени — точное совпадение доверяется jq.
#
# Отбирается версия, чьё имя целиком совпадает с формой технического тега.
# Проверять «начинается с sha-» недостаточно: под шаблон попал бы и осмысленный
# тег вроде sha-experiment. Версии с именем sha256:… не трогаются вовсе — в
# Gitea такая запись может быть частью живого образа, и удаление разобрало бы
# его.
LIMIT=50
PAGE=1
TAGGED=''

while :; do
  BATCH=$(curl "${CURL_ARGS[@]}" "$API?type=container&q=$PACKAGE&page=$PAGE&limit=$LIMIT")

  SELECTED=$(
    printf '%s' "$BATCH" | jq -r --arg pkg "$PACKAGE" '
      .[]
      | select(.name == $pkg)
      | select(.version | test("^sha-[0-9a-f]{7}$"))
      | [.version, .created_at]
      | @tsv
    '
  )

  if [ -n "$SELECTED" ]; then
    TAGGED="${TAGGED}${SELECTED}"$'\n'
  fi

  COUNT=$(printf '%s' "$BATCH" | jq 'length')
  if [ "$COUNT" -lt "$LIMIT" ]; then
    break
  fi

  PAGE=$((PAGE + 1))
done

# Возраст сверяется здесь, а не в jq: Gitea отдаёт время со смещением часового
# пояса сервера, а jq умеет разбирать только форму с Z и падает на остальных.
FOUND=0

while IFS=$'\t' read -r version created; do
  [ -n "$version" ] || continue
  [ "$(date -d "$created" +%s)" -lt "$CUTOFF" ] || continue

  FOUND=$((FOUND + 1))
  echo "$version  $created"

  if [ "$SHOW_ONLY" = 'true' ]; then
    continue
  fi

  curl "${CURL_ARGS[@]}" -X DELETE "$API/container/$PACKAGE/$version"
  echo "  удалено"
done <<<"$TAGGED"

if [ "$FOUND" -eq 0 ]; then
  echo "Удалять нечего."
fi
