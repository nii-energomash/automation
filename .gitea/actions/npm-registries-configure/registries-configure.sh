#!/usr/bin/env bash
set -euo pipefail

NPMRC="${HOME}/.npmrc"
STRICT_SSL="${STRICT_SSL:-true}"

if [ "$STRICT_SSL" != "true" ] && [ "$STRICT_SSL" != "false" ]; then
    echo "❌ STRICT_SSL must be 'true' or 'false'"
    exit 1
fi

echo "Generating ${NPMRC}"
: >"$NPMRC"

# Команды раннера вида ::add-mask:: в Gitea Actions не документированы.
# Если раннер такую строку не разберёт, она уйдёт в лог вместе с токеном,
# поэтому здесь маскировки нет — токен просто нигде не печатается.

declare -A REGISTRIES=()

while IFS= read -r registry_src; do
    [ -z "$registry_src" ] && continue

    echo "$registry_src" >>"$NPMRC"

    # Строка без ':registry=' попадает в ~/.npmrc как есть, но хост из неё
    # не выводится: ключом стала бы вся строка целиком.
    case "$registry_src" in
        *:registry=*) ;;
        *) continue ;;
    esac

    registry_key="${registry_src#*:registry=}"
    registry_key="${registry_key#http://}"
    registry_key="${registry_key#https://}"

    # npm сопоставляет ключ вида //host[/path]/:_authToken= — с ровно одним
    # завершающим слэшем. Адрес реестра пишут и со слэшем, и без него.
    registry_key="${registry_key%/}/"

    REGISTRIES["$registry_key"]=1
done <<EOF
${SCOPES_WITH_REGISTERS}
EOF

if [ -z "${NODE_AUTH_TOKEN:-}" ]; then
    echo "🔓 NODE_AUTH_TOKEN не задан, строки с токеном не добавлены"
elif [ "${#REGISTRIES[@]}" -eq 0 ]; then
    echo "🔓 Ни одной строки с ':registry=' не передано, токен добавлять некуда"
else
    for registry_key in "${!REGISTRIES[@]}"; do
        echo "//${registry_key}:_authToken=${NODE_AUTH_TOKEN}" >>"$NPMRC"
    done
    echo "🔑 NPM токен добавлен для ${#REGISTRIES[@]} registry"
fi

echo "strict-ssl=${STRICT_SSL}" >>"$NPMRC"

echo "📝 Конфигурация NPM сохранена в ${NPMRC}"

echo ""
echo "📄 Содержимое ${NPMRC} (значение токена скрыто):"
echo "----------------------------------------"
sed -E 's/(_authToken=).*/\1***/' "$NPMRC"
echo "----------------------------------------"
