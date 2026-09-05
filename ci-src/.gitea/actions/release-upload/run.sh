#!/usr/bin/env bash
# источник: nii-energomash/automation/ci-src/.gitea/actions/release-upload/run.sh
# место: .gitea/actions/release-upload/run.sh

# Прикрепляет файлы к релизу Gitea. Ожидает в окружении TAG, FILES и GT_TOKEN
# (их задаёт action.yml), GITHUB_SERVER_URL и GITHUB_REPOSITORY (их задаёт
# раннер).
#
# Аналога gh release upload у площадки нет, поэтому вызывается API напрямую:
# сначала релиз ищется по тегу, затем в него грузятся вложения.
set -euo pipefail

# Gitea отвечает по https с самоподписанным сертификатом. Раннер монтирует CA в
# задание и указывает на него SSL_CERT_FILE; curl эту переменную сам не
# смотрит, поэтому путь передаётся явно.
CURL_ARGS=(--fail --silent --show-error -H "Authorization: token $GT_TOKEN")
if [ -n "${SSL_CERT_FILE:-}" ] && [ -f "$SSL_CERT_FILE" ]; then
  CURL_ARGS+=(--cacert "$SSL_CERT_FILE")
fi

if ! command -v jq >/dev/null; then
  apt-get update -qq
  apt-get install -y -qq jq
fi

API="$GITHUB_SERVER_URL/api/v1/repos/$GITHUB_REPOSITORY/releases"

# Идентификатор берётся запросом по тегу, а не из полезной нагрузки события:
# так шаг не зависит от её формы и работает при повторном запуске.
RELEASE_ID=$(curl "${CURL_ARGS[@]}" "$API/tags/$TAG" | jq -r '.id')

if [ -z "$RELEASE_ID" ] || [ "$RELEASE_ID" = 'null' ]; then
  echo "Релиз с тегом '$TAG' не найден" >&2
  exit 1
fi

echo "Релиз: $TAG (id $RELEASE_ID)"

while read -r file; do
  [ -n "$file" ] || continue

  if [ ! -f "$file" ]; then
    echo "Файл '$file' не найден" >&2
    exit 1
  fi

  # Имя вложения задаётся явно: без него Gitea берёт его из multipart-поля, а
  # там лежит путь целиком.
  name=$(basename "$file")
  curl "${CURL_ARGS[@]}" -X POST \
    -F "attachment=@$file" \
    "$API/$RELEASE_ID/assets?name=$name" > /dev/null
  echo "  прикреплено: $name"
done <<<"$FILES"
