#!/usr/bin/env bash
set -euo pipefail

#######################################
# Required environment variables
#######################################

: "${GITHUB_REPOSITORY:?GITHUB_REPOSITORY is required (owner/repo)}"
: "${GITHUB_REPOSITORY_OWNER:?GITHUB_REPOSITORY_OWNER is required}"

#######################################
# Inputs with defaults
#######################################

DAYS_OLD="${DAYS_OLD:-0}"
HOURS_OLD="${HOURS_OLD:-1}"
SHOW_ONLY="${SHOW_ONLY:-false}"
TAG_PREFIX="${TAG_PREFIX:-sha-}"
IMAGE_NAME="${IMAGE_NAME:-$GITHUB_REPOSITORY}"

#######################################
# Derived values
#######################################

OWNER="$GITHUB_REPOSITORY_OWNER"

# Имя образа задаётся так же, как при публикации, то есть вместе с владельцем
# (owner/name). В API пакетов владелец идёт отдельным сегментом пути, поэтому
# префикс отрезается, а оставшиеся '/' кодируются: имя пакета — один сегмент.
PACKAGE_NAME="${IMAGE_NAME#"${OWNER}/"}"
PACKAGE_NAME="${PACKAGE_NAME//\//%2F}"

#######################################
# Validation
#######################################

if [[ -z "$PACKAGE_NAME" ]]; then
  echo "❌ IMAGE_NAME не задаёт имя пакета: '${IMAGE_NAME}'"
  exit 1
fi

if ! [[ "$TAG_PREFIX" =~ ^[A-Za-z0-9._-]+$ ]]; then
  echo "❌ TAG_PREFIX must contain only [A-Za-z0-9._-]"
  exit 1
fi

if ! [[ "$DAYS_OLD" =~ ^[0-9]+$ ]]; then
  echo "❌ DAYS_OLD must be a non-negative integer"
  exit 1
fi

if ! [[ "$HOURS_OLD" =~ ^([0-9]|1[0-9]|2[0-3])$ ]]; then
  echo "❌ HOURS_OLD must be in range 0–23"
  exit 1
fi

if [[ "$SHOW_ONLY" != "true" && "$SHOW_ONLY" != "false" ]]; then
  echo "❌ SHOW_ONLY must be 'true' or 'false'"
  exit 1
fi

#######################################
# Package endpoint
#######################################

# Путь до пакета зависит от того, кому он принадлежит: у организации это
# /orgs/{org}/packages/..., у пользователя — /users/{username}/packages/...
# Перепутанный путь даёт 404, поэтому тип владельца выясняется в рантайме,
# а не зашивается в скрипт.
OWNER_TYPE="$(gh api "users/${OWNER}" --jq '.type' 2>/dev/null || true)"

case "$OWNER_TYPE" in
  Organization) OWNER_PATH="orgs/${OWNER}" ;;
  User) OWNER_PATH="users/${OWNER}" ;;
  *)
    echo "❌ Не удалось определить тип владельца '${OWNER}'"
    echo "   Получено: '${OWNER_TYPE:-<пусто>}', ожидалось 'Organization' или 'User'"
    exit 1
    ;;
esac

PACKAGE_PATH="${OWNER_PATH}/packages/container/${PACKAGE_NAME}"

#######################################
# Time calculation
#######################################

CUTOFF_TS="$(date -d "${DAYS_OLD} days ${HOURS_OLD} hours ago" +%s)"

echo "🧹 Docker cleanup"
echo "Owner:        $OWNER ($OWNER_TYPE)"
echo "Image name:   $IMAGE_NAME"
echo "Package path: $PACKAGE_PATH"
echo "Tag prefix:   $TAG_PREFIX"
echo "Days old:     $DAYS_OLD"
echo "Hours old:    $HOURS_OLD"
echo "Show only:    $SHOW_ONLY"
echo "Cutoff time:  $(date -d "@$CUTOFF_TS")"
echo

#######################################
# Fetch package versions
#######################################

echo "📦 Fetching container versions…"

# any(...) вместо tags[]?: с генератором внутри select версия попадала
# в выборку столько раз, сколько у неё подходящих тегов, и один и тот же
# id удалялся дважды.
JQ_FILTER="
  .[]
  | select(any(.metadata.container.tags[]?; startswith(\"${TAG_PREFIX}\")))
  | select((.updated_at | fromdateiso8601) < ${CUTOFF_TS})
  | {
      id: .id,
      updated_at: .updated_at,
      tags: .metadata.container.tags
    }
"

if ! CANDIDATES="$(gh api "${PACKAGE_PATH}/versions" --paginate --jq "$JQ_FILTER")"; then
  echo "❌ Не удалось получить список версий пакета по пути ${PACKAGE_PATH}"
  exit 1
fi

#######################################
# Process candidates
#######################################

FOUND=0
DELETED=0
SKIPPED=0

while IFS= read -r version; do
  [ -z "$version" ] && continue

  FOUND=$((FOUND + 1))

  ID="$(jq -r '.id' <<<"$version")"
  TAGS="$(jq -r '.tags | join(", ")' <<<"$version")"
  UPDATED="$(jq -r '.updated_at' <<<"$version")"

  echo "→ Found candidate:"
  echo "    id:         $ID"
  echo "    tags:       $TAGS"
  echo "    updated_at: $UPDATED"

  if [[ "$SHOW_ONLY" == "true" ]]; then
    echo "    (dry-run, not deleting)"
    echo
    continue
  fi

  echo "    Deleting version $ID"

  # Версию мог удалить параллельный прогон, поэтому 404 — не ошибка.
  if DELETE_OUTPUT="$(gh api --method DELETE "${PACKAGE_PATH}/versions/${ID}" --silent </dev/null 2>&1)"; then
    DELETED=$((DELETED + 1))
  elif grep -q "HTTP 404" <<<"$DELETE_OUTPUT"; then
    echo "    ⏭️  Версия уже отсутствует (404)"
    SKIPPED=$((SKIPPED + 1))
  else
    echo "    ❌ Не удалось удалить версию $ID"
    echo "$DELETE_OUTPUT"
    exit 1
  fi

  echo
done <<<"$CANDIDATES"

#######################################
# Summary
#######################################

echo "✅ Готово"
echo "   Кандидатов найдено: $FOUND"

if [[ "$SHOW_ONLY" == "true" ]]; then
  echo "   Удалено:            0 (dry-run)"
else
  echo "   Удалено:            $DELETED"
  echo "   Пропущено (404):    $SKIPPED"
fi
