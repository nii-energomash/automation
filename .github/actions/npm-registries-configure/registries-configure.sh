#!/usr/bin/env bash
set -euo pipefail

if [ -z "$NODE_AUTH_TOKEN" ]; then
    echo "❌ При указании scope+registry требуется NPM токен"
    exit 1
fi

echo "Generating ~/.npmrc"
: > ~/.npmrc

while IFS= read -r registry_src; do
    [ -z "$registry_src" ] && continue
    echo "$registry_src" >> ~/.npmrc
done <<'EOF'
${SCOPES_WITH_REGISTERS}
EOF

echo "//npm.pkg.github.com/:_authToken=${NODE_AUTH_TOKEN}" >> ~/.npmrc
