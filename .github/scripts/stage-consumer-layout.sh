#!/usr/bin/env bash

# Раскладывает шаблоны из ci-src/ во временный каталог так, как они лежат у
# потребителя, — по путям из строк «# место:».
#
# Нужно ради actionlint: шаблоны ссылаются на соседние экшены как
# `uses: ./.ci/actions/…`, то есть от корня репозитория-потребителя. Здесь
# такого пути нет, и без раскладки линтер спотыкается на каждом обращении.
# На стенде он вдобавок сверяет with: со списком inputs локального экшена —
# проверка, ради которой стенд и городится.
#
# Запускается из корня репозитория: stage-consumer-layout.sh <каталог>
set -euo pipefail

if [ "$#" -ne 1 ]; then
  printf 'Использование: %s <каталог стенда>\n' "$0" >&2
  exit 2
fi

stage=$1

mkdir -p "$stage"
if [ -n "$(ls -A "$stage")" ]; then
  printf 'Каталог стенда %s не пуст\n' "$stage" >&2
  exit 2
fi

list_file=$(mktemp)
trap 'rm -f "$list_file"' EXIT
find ci-src -type f ! -name README.md | sort > "$list_file"

while IFS= read -r file; do
  place=$(sed -n 's/^# место: //p' "$file" | head -n 1)
  if [ -z "$place" ]; then
    printf '%s: нет строки «# место:»\n' "$file" >&2
    exit 1
  fi

  # У воркфлоу сегмент типа при копировании выбрасывается, и на один целевой
  # ci.yml претендуют несколько источников. На стенде они должны лежать рядом,
  # поэтому тип возвращается в имя файла: линтер имени не разбирает, а
  # коллизии снимаются без раскладки на шесть отдельных деревьев.
  case "$file" in
    ci-src/*/workflows/*)
      type=${file#ci-src/*/workflows/}
      type=${type%%/*}
      target="$stage/$(dirname "$place")/$type-$(basename "$file")"
      ;;
    *)
      target="$stage/$place"
      ;;
  esac

  mkdir -p "$(dirname "$target")"
  cp "$file" "$target"
done < "$list_file"

# Без своего .git actionlint не находит корень проекта и не резолвит
# ./-пути до локальных экшенов.
git init -q "$stage"

printf 'Стенд собран в %s\n' "$stage"
