#!/usr/bin/env bash
# источник: nii-energomash/automation/ci-src/.ci/actions/prepare-npm-release/run.sh
# место: .ci/actions/prepare-npm-release/run.sh

# Проставляет версию из git-тега и выбирает dist-tag публикации.
# Ожидает в окружении TAG, PRERELEASE, MANIFEST_DIR, TAG_PATTERN, TAG_GLOB,
# LTS_PREFIX и GITHUB_OUTPUT (их задаёт action.yml).
set -eu

if ! printf '%s' "$TAG" | grep -Eq "$TAG_PATTERN"; then
  echo "Тег '$TAG' не соответствует формату vX.Y.Z" >&2
  exit 1
fi

# Манифест лежит в подкаталоге, а git-команды ниже должны остаться в корне
# репозитория, поэтому каталог меняется только на время npm version.
(cd "$MANIFEST_DIR" && npm version --no-git-tag-version --allow-same-version "${TAG#v}")

# latest достаётся только старшей версии. Патч линии сопровождения,
# выпущенный после новой мажорной, иначе увёл бы latest назад.
if [ "$PRERELEASE" = 'true' ]; then
  NPM_TAG='next'
else
  HIGHEST=$(git tag --list "$TAG_GLOB" --sort=v:refname \
    | grep -E "$TAG_PATTERN" | tail -n 1)
  if [ "$TAG" = "$HIGHEST" ]; then
    NPM_TAG='latest'
  else
    NPM_TAG="${LTS_PREFIX}${TAG%%.*}"
    echo "$TAG не старший тег (старший — $HIGHEST)"
  fi
fi

# Имя, читаемое как версия, реестр Gitea отвергает уже приняв tarball:
# пакет опубликован, прогон красный. Ловим до публикации.
if printf '%s' "$NPM_TAG" | grep -Eq '^v?[0-9]'; then
  echo "dist-tag '$NPM_TAG' начинается как версия — реестр отвергнет его" >&2
  exit 1
fi

echo "npm-tag=$NPM_TAG" >> "$GITHUB_OUTPUT"
echo "Тег: $TAG, версия: ${TAG#v}, dist-tag: $NPM_TAG"
