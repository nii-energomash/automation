#!/usr/bin/env bash
set -euo pipefail

echo "Generating ~/.npmrc"
: > ~/.npmrc

declare -A REGISTRIES=()

while IFS= read -r registry_src; do
    [ -z "$registry_src" ] && continue

    echo "$registry_src" >> ~/.npmrc

    if [ -n "${NODE_AUTH_TOKEN:-}" ]; then
        registry_url="${registry_src#*:registry=}"

        registry_no_proto="${registry_url#http://}"
        registry_no_proto="${registry_no_proto#https://}"
        # registry_no_proto="${registry_no_proto%/}"

        REGISTRIES["$registry_no_proto"]=1
    fi

done <<EOF
${SCOPES_WITH_REGISTERS}
EOF

if [ -n "${NODE_AUTH_TOKEN:-}" ]; then
    for registry in "${!REGISTRIES[@]}"; do
        echo "//${registry}:_authToken=${NODE_AUTH_TOKEN}" >> ~/.npmrc
    done
    echo "🔑 NPM токен добавлен для ${#REGISTRIES[@]} registry"
else
    echo "🔓 NODE_AUTH_TOKEN не задан, строка с токеном не добавлена"
fi

echo ""
echo "📄 Содержимое ~/.npmrc:"
echo "----------------------------------------"
cat ~/.npmrc
echo "----------------------------------------"
