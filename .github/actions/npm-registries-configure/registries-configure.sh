#!/usr/bin/env bash
set -euo pipefail

echo "Generating ~/.npmrc"
: > ~/.npmrc

while IFS= read -r registry_src; do
    [ -z "$registry_src" ] && continue
    echo "$registry_src" >> ~/.npmrc
done <<'EOF'
${SCOPES_WITH_REGISTERS}
EOF

if [ -n "${NODE_AUTH_TOKEN:-}" ]; then
    echo "//npm.pkg.github.com/:_authToken=${NODE_AUTH_TOKEN}" >> ~/.npmrc
    echo "🔑 NPM токен добавлен в конфигурацию"
else
    echo "🔓 NODE_AUTH_TOKEN не задан, строка с токеном не добавлена"
fi

echo "📝 Конфигурация NPM сохранена в ~/.npmrc"

echo ""
echo "📄 Содержимое ~/.npmrc:"
echo "----------------------------------------"
cat ~/.npmrc
echo "----------------------------------------"
