#!/usr/bin/env bash
# источник: nii-energomash/automation/ci-src/.ci/actions/version-from-tag/run.sh
# место: .ci/actions/version-from-tag/run.sh

# Сверяет формат git-тега и выводит версию сервиса.
# Ожидает в окружении TAG, TAG_PATTERN и GITHUB_OUTPUT (их задаёт action.yml).
set -eu

if ! printf '%s' "$TAG" | grep -Eq "$TAG_PATTERN"; then
  echo "Тег '$TAG' не соответствует формату vX.Y.Z" >&2
  exit 1
fi

echo "version=${TAG#v}" >> "$GITHUB_OUTPUT"
echo "Тег: $TAG, версия: ${TAG#v}"
