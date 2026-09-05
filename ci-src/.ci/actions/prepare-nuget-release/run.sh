#!/usr/bin/env bash
# источник: nii-energomash/automation/ci-src/.ci/actions/prepare-nuget-release/run.sh
# место: .ci/actions/prepare-nuget-release/run.sh

# Проверяет формат релизного тега и достаёт из него номер версии.
# Ожидает в окружении TAG, TAG_PATTERN и GITHUB_OUTPUT (их задаёт action.yml).
#
# Версия в проекте не хранится: её получает dotnet build/pack через -p:Version.
# Поэтому шаг ничего не правит в рабочей копии, а только вычисляет.
set -eu

if ! printf '%s' "$TAG" | grep -Eq "$TAG_PATTERN"; then
  echo "Тег '$TAG' не соответствует формату vX.Y.Z" >&2
  exit 1
fi

VERSION="${TAG#v}"

echo "tag=$TAG" >> "$GITHUB_OUTPUT"
echo "version=$VERSION" >> "$GITHUB_OUTPUT"
echo "Тег: $TAG, версия: $VERSION"
