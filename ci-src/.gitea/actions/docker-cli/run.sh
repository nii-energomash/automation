#!/usr/bin/env bash
# источник: nii-energomash/automation/ci-src/.gitea/actions/docker-cli/run.sh
# место: .gitea/actions/docker-cli/run.sh

# Ставит docker CLI и плагин buildx, если их нет в образе задания.
# Ожидает в окружении CLI_VERSION и BUILDX_VERSION (их задаёт action.yml).
#
# Ставится клиент, без демона: демон берётся с хоста через проброшенный сокет.
# Пакета docker-ce-cli в дистрибутиве нет, а docker.io притащил бы за собой
# второй демон, поэтому статическая сборка с download.docker.com.
#
# buildx здесь не удобство, а условие сборки: Dockerfile сервиса пользуется
# директивой syntax и секретом (RUN --mount=type=secret), а классический
# сборщик не умеет ни того, ни другого. Без плагина docker build молча уедет
# на классический и упадёт на первой же директиве.
set -eu

if ! command -v docker >/dev/null; then
  curl -fsSL "https://download.docker.com/linux/static/stable/x86_64/docker-${CLI_VERSION}.tgz" \
    | tar -xz -C /usr/local/bin --strip-components=1 docker/docker
fi

docker --version

if ! docker buildx version >/dev/null 2>&1; then
  PLUGINS="$HOME/.docker/cli-plugins"
  mkdir -p "$PLUGINS"
  curl -fsSL -o "$PLUGINS/docker-buildx" \
    "https://github.com/docker/buildx/releases/download/v${BUILDX_VERSION}/buildx-v${BUILDX_VERSION}.linux-amd64"
  chmod +x "$PLUGINS/docker-buildx"
fi

docker buildx version
