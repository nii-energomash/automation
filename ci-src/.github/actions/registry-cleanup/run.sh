#!/usr/bin/env bash
# источник: nii-energomash/automation/ci-src/.github/actions/registry-cleanup/run.sh
# место: .github/actions/registry-cleanup/run.sh

# Удаляет из ghcr.io технические образы: версии с тегами sha-* и оставшиеся без
# тегов манифесты старше заданного возраста. Релизные теги и latest не трогаются
# никогда.
# Ожидает в окружении DAYS_OLD, HOURS_OLD, SHOW_ONLY, GH_TOKEN (их задаёт
# action.yml), GITHUB_REPOSITORY и GITHUB_REPOSITORY_OWNER (их задаёт раннер).
set -euo pipefail

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

OWNER="$GITHUB_REPOSITORY_OWNER"
PACKAGE="${GITHUB_REPOSITORY#*/}"
VERSIONS="/orgs/$OWNER/packages/container/$PACKAGE/versions"
# Смещение задаётся знаком, а не словом ago: ago в date относится только к
# последней единице, и «1 days 0 hours ago» уехало бы на сутки вперёд, а не
# назад — тогда под удаление попадала бы версия любого возраста.
CUTOFF=$(date -d "-$DAYS_OLD days -$HOURS_OLD hours" +%s)

echo "Пакет:   $OWNER/$PACKAGE"
echo "Граница: $(date -d "@$CUTOFF" --iso-8601=seconds) (старше $DAYS_OLD д. $HOURS_OLD ч.)"
if [ "$SHOW_ONLY" = 'true' ]; then
  echo "Режим:   только показать"
else
  echo "Режим:   удаление"
fi
echo

# Эндпоинт организации, а не пользователя: репозиторий принадлежит организации,
# и /users/ отвечает на него 404.
#
# Под удаление идёт версия, у которой все теги начинаются с sha-, либо тегов нет
# вовсе (all по пустому списку истинно). Проверять «хоть один тег начинается с
# sha-» нельзя: версия, у которой рядом с sha-тегом висит latest, уехала бы
# вместе с latest.
#
# Отбор целиком выполняет gh своим встроенным jq, отдельного jq в задании не
# требуется. Граница подставляется в выражение числом — она сверена выше.
CANDIDATES=$(
  gh api "$VERSIONS" --paginate --jq '
    .[]
    | { id, updated_at, tags: (.metadata.container.tags // []) }
    | select((.updated_at | fromdateiso8601) < '"$CUTOFF"')
    | select(all(.tags[]; startswith("sha-")))
    | [.id, .updated_at, (.tags | join(","))]
    | @tsv
  '
)

if [ -z "$CANDIDATES" ]; then
  echo "Удалять нечего."
  exit 0
fi

while IFS=$'\t' read -r id updated tags; do
  [ -n "$id" ] || continue

  echo "$id  $updated  ${tags:-без тегов}"

  if [ "$SHOW_ONLY" = 'true' ]; then
    continue
  fi

  gh api --method DELETE "$VERSIONS/$id" --silent
  echo "  удалено"
done <<<"$CANDIDATES"
