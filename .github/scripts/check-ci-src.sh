#!/usr/bin/env bash

# Проверяет то, что ломается молча: шапки копируемых файлов, полноту
# docs/copy-map.md в обе стороны и состав корневого .github/.
# Запускается из корня репозитория, ничего не меняет.
set -euo pipefail

readonly ORIGIN_PREFIX='nii-energomash/automation/'
readonly MAP='docs/copy-map.md'

errors=0

fail() {
  printf '%s\n' "$1" >&2
  errors=$((errors + 1))
}

# Пары «источник → место» из таблиц карты. Берутся строки, чья первая ячейка
# начинается с ci-src/, и из каждой ячейки — первый фрагмент в обратных
# кавычках: так снимается хвост вида «`.github/workflows/ci.yml` — один из».
# Строка-пример в шапке карты повторяет настоящую запись, дубли снимает sort -u.
map_pairs() {
  awk '
    /^\|[[:space:]]*`ci-src\// {
      n = split($0, cell, "|")
      src = ""
      dst = ""
      for (i = 2; i <= n; i++) {
        if (match(cell[i], /`[^`]+`/)) {
          value = substr(cell[i], RSTART + 1, RLENGTH - 2)
          if (src == "") {
            src = value
          } else if (dst == "") {
            dst = value
          }
        }
      }
      if (src != "" && dst != "") {
        print src "\t" dst
      }
    }
  ' "$MAP" | sort -u
}

header_value() {
  sed -n "s/^# $2: //p" "$1" | head -n 1
}

pairs_file=$(mktemp)
list_file=$(mktemp)
trap 'rm -f "$pairs_file" "$list_file"' EXIT

map_pairs > "$pairs_file"

if [ ! -s "$pairs_file" ]; then
  fail "$MAP: не разобрана ни одна строка таблицы — карта пуста или сломана"
fi

# Шапки: строка происхождения обязана совпадать с фактическим путём, строка
# места — с записью в карте. README.md не копируется и шапки не имеет.
find ci-src -type f ! -name README.md | sort > "$list_file"

while IFS= read -r file; do
  origin=$(header_value "$file" 'источник')
  place=$(header_value "$file" 'место')

  if [ -z "$origin" ]; then
    fail "$file: нет строки «# источник:»"
  elif [ "$origin" != "$ORIGIN_PREFIX$file" ]; then
    fail "$file: «# источник: $origin» не совпадает с путём файла"
  fi

  if [ -z "$place" ]; then
    fail "$file: нет строки «# место:»"
    continue
  fi

  if ! grep -qxF "$file"$'\t'"$place" "$pairs_file"; then
    fail "$file: пары «$file → $place» нет в $MAP"
  fi
done < "$list_file"

# Обратная сторона: в карте не должно быть записей о несуществующих файлах.
while IFS=$'\t' read -r src _; do
  if [ ! -f "$src" ]; then
    fail "$MAP: запись о несуществующем файле $src"
  fi
done < "$pairs_file"

# Замок на корневой .github/: шаблон, попавший сюда, перестаёт быть шаблоном.
# Для dependabot.yml это особенно дёшево — ему довольно имени и места, триггер
# не нужен.
find .github -type f | sort > "$list_file"

while IFS= read -r file; do
  case "$file" in
    .github/dependabot.yml | .github/workflows/ci.yml) ;;
    .github/scripts/*.sh) ;;
    *)
      fail "$file: в корневом .github/ лишний файл — здесь допустимы только
свои ci.yml, dependabot.yml и scripts/*.sh"
      ;;
  esac
done < "$list_file"

if [ "$errors" -ne 0 ]; then
  printf 'Ошибок: %d\n' "$errors" >&2
  exit 1
fi

printf 'Шапки, карта копирования и состав .github/ в порядке.\n'
