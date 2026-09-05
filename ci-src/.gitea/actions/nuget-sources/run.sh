#!/usr/bin/env bash
# источник: nii-energomash/automation/ci-src/.gitea/actions/nuget-sources/run.sh
# место: .gitea/actions/nuget-sources/run.sh

# Собирает файл источников NuGet для восстановления на раннере Gitea.
# Ожидает в окружении REGISTRY, OWNER, PATTERNS, CONFIG_PATH (их задаёт
# action.yml) и GITHUB_OUTPUT (его задаёт раннер).
#
# Файл собирается здесь, а не лежит в репозитории, потому что адреса инстанса в
# репозитории нет вовсе: он приходит переменной репозитория Gitea.
#
# Список полный, включая nuget.org и маппинг для него: файл, переданный через
# --configfile, заменяет всю цепочку конфигов, а не дополняет её.
set -eu

if [ -z "$REGISTRY" ]; then
  echo 'Не задан адрес инстанса — переменная репозитория REGISTRY_HOST' >&2
  exit 1
fi

if [ -z "$OWNER" ]; then
  echo 'Не задан владелец пакетов — переменная репозитория REGISTRY_OWNER' >&2
  exit 1
fi

if [ -z "${PATTERNS//[[:space:]]/}" ]; then
  echo 'Не заданы маски пакетов реестра Gitea — вход patterns' >&2
  exit 1
fi

# Маппинг без масок означал бы, что из реестра Gitea не берётся ничего, и
# восстановление молча ушло бы на nuget.org — с ошибкой не про источники.
mapping=''
while IFS= read -r pattern; do
  pattern=${pattern//[[:space:]]/}
  [ -n "$pattern" ] || continue
  mapping="$mapping      <package pattern=\"$pattern\" />"$'\n'
done <<EOF
$PATTERNS
EOF

cat > "$CONFIG_PATH" <<EOF
<?xml version="1.0" encoding="utf-8"?>
<configuration>
  <packageSources>
    <clear />
    <add key="nuget.org" value="https://api.nuget.org/v3/index.json" />
    <add key="gitea" value="https://$REGISTRY/api/packages/$OWNER/nuget/index.json" />
  </packageSources>

  <packageSourceCredentials>
    <gitea>
      <add key="Username" value="$OWNER" />
      <add key="ClearTextPassword" value="%GT_PACKAGES_TOKEN%" />
    </gitea>
  </packageSourceCredentials>

  <packageSourceMapping>
    <packageSource key="nuget.org">
      <package pattern="*" />
    </packageSource>
    <packageSource key="gitea">
$mapping    </packageSource>
  </packageSourceMapping>
</configuration>
EOF

echo "configfile=$CONFIG_PATH" >> "$GITHUB_OUTPUT"
echo "Источники: nuget.org и https://$REGISTRY/api/packages/$OWNER/nuget/"
