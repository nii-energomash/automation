# Что куда копируется

Полный перечень «файл здесь → путь у потребителя», без правил, которые надо
применять в уме. Правило, по которому эти пути получены, описано в
[conventions.md](conventions.md); таблица от него не зависит и читается сама
по себе.

Таблица пополняется каждым переносом. Её полнота — предмет самопроверки
репозитория: под `ci-src/` не должно оставаться файлов, которых здесь нет.

Форма записи — путь от корня репозитория и путь от корня проекта-потребителя:

| Здесь                                 | У потребителя              |
| ------------------------------------- | -------------------------- |
| `ci-src/.github/workflows/npm/ci.yml` | `.github/workflows/ci.yml` |

## Экшены

Общие для GitHub и Gitea, копируются каталогом целиком.

| Здесь                                                 | У потребителя                                  |
| ----------------------------------------------------- | ---------------------------------------------- |
| `ci-src/.ci/actions/prepare-npm-release/action.yml`   | `.ci/actions/prepare-npm-release/action.yml`   |
| `ci-src/.ci/actions/prepare-npm-release/run.sh`       | `.ci/actions/prepare-npm-release/run.sh`       |
| `ci-src/.ci/actions/prepare-nuget-release/action.yml` | `.ci/actions/prepare-nuget-release/action.yml` |
| `ci-src/.ci/actions/prepare-nuget-release/run.sh`     | `.ci/actions/prepare-nuget-release/run.sh`     |
| `ci-src/.ci/actions/version-from-tag/action.yml`      | `.ci/actions/version-from-tag/action.yml`      |
| `ci-src/.ci/actions/version-from-tag/run.sh`          | `.ci/actions/version-from-tag/run.sh`          |

Назначение каждого — в [actions.md](actions.md).

## Площадочные экшены

Копируются каталогом целиком, как и общие; в `.ci/` не попадают, потому что
обращаются к API или окружению одной площадки.

| Здесь                                                    | У потребителя                                       |
| -------------------------------------------------------- | --------------------------------------------------- |
| `ci-src/.github/actions/registry-cleanup/action.yml`     | `.github/actions/registry-cleanup/action.yml`       |
| `ci-src/.github/actions/registry-cleanup/run.sh`         | `.github/actions/registry-cleanup/run.sh`           |
| `ci-src/.gitea/actions/docker-cli/action.yml`            | `.gitea/actions/docker-cli/action.yml`              |
| `ci-src/.gitea/actions/docker-cli/run.sh`                | `.gitea/actions/docker-cli/run.sh`                  |
| `ci-src/.gitea/actions/nuget-sources/action.yml`         | `.gitea/actions/nuget-sources/action.yml`           |
| `ci-src/.gitea/actions/nuget-sources/run.sh`             | `.gitea/actions/nuget-sources/run.sh`               |
| `ci-src/.gitea/actions/registry-cleanup/action.yml`      | `.gitea/actions/registry-cleanup/action.yml`        |
| `ci-src/.gitea/actions/registry-cleanup/run.sh`          | `.gitea/actions/registry-cleanup/run.sh`            |
| `ci-src/.gitea/actions/release-upload/action.yml`        | `.gitea/actions/release-upload/action.yml`          |
| `ci-src/.gitea/actions/release-upload/run.sh`            | `.gitea/actions/release-upload/run.sh`              |

## GitHub

Сегмент типа проекта при копировании выбрасывается.

| Здесь                                                | У потребителя                            |
| ---------------------------------------------------- | ---------------------------------------- |
| `ci-src/.github/workflows/npm/ci.yml`                | `.github/workflows/ci.yml`               |
| `ci-src/.github/workflows/npm/publish.yml`           | `.github/workflows/publish.yml`          |
| `ci-src/.github/workflows/nuget/ci.yml`              | `.github/workflows/ci.yml`               |
| `ci-src/.github/workflows/nuget/publish.yml`         | `.github/workflows/publish.yml`          |
| `ci-src/.github/workflows/docker/ci-python.yml`      | `.github/workflows/ci.yml` — один из     |
| `ci-src/.github/workflows/docker/ci-dotnet.yml`      | `.github/workflows/ci.yml` — двух        |
| `ci-src/.github/workflows/docker/publish-sha.yml`    | `.github/workflows/publish-sha.yml`      |
| `ci-src/.github/workflows/docker/release.yml`        | `.github/workflows/release.yml`          |
| `ci-src/.github/workflows/docker/registry-cleanup.yml` | `.github/workflows/registry-cleanup.yml` |

Релизные модели наборов — в [npm.md](npm.md), [nuget.md](nuget.md) и
[docker.md](docker.md).

## Gitea

| Здесь                                               | У потребителя                           |
| --------------------------------------------------- | --------------------------------------- |
| `ci-src/.gitea/workflows/npm/ci.yml`                | `.gitea/workflows/ci.yml`               |
| `ci-src/.gitea/workflows/npm/publish.yml`           | `.gitea/workflows/publish.yml`          |
| `ci-src/.gitea/workflows/nuget/ci.yml`              | `.gitea/workflows/ci.yml`               |
| `ci-src/.gitea/workflows/nuget/publish.yml`         | `.gitea/workflows/publish.yml`          |
| `ci-src/.gitea/workflows/docker/ci-python.yml`      | `.gitea/workflows/ci.yml` — один из     |
| `ci-src/.gitea/workflows/docker/ci-dotnet.yml`      | `.gitea/workflows/ci.yml` — двух        |
| `ci-src/.gitea/workflows/docker/publish-sha.yml`    | `.gitea/workflows/publish-sha.yml`      |
| `ci-src/.gitea/workflows/docker/release.yml`        | `.gitea/workflows/release.yml`          |
| `ci-src/.gitea/workflows/docker/registry-cleanup.yml` | `.gitea/workflows/registry-cleanup.yml` |

Единственное место, где путь не однозначен, — `ci-python.yml` и `ci-dotnet.yml`
docker-набора: у потребителя это один файл `ci.yml`, и берётся тот вариант, что
подходит языку проекта. Почему у docker-набора нет общего `ci.yml` — в
[docker.md](docker.md).

Чем gitea-вариант отличается от github-варианта — в [npm.md](npm.md),
[nuget.md](nuget.md) и [docker.md](docker.md).

## Dependabot

Копируется один в один и только на GitHub: в Gitea Dependabot отсутствует как
явление. Что в этом файле есть, чего нет и почему — в
[dependabot.md](dependabot.md).

| Здесь                           | У потребителя            |
| ------------------------------- | ------------------------ |
| `ci-src/.github/dependabot.yml` | `.github/dependabot.yml` |

## Раннер Gitea

В репозиторий-потребитель не копируется вовсе: место назначения — каталог
раннера на хосте, `<runner-dir>`. Строка `# место:` в шапке указывает путь
внутри него. Установка и остальные плейсхолдеры — в
[gitea-runner.md](gitea-runner.md).

| Здесь                                       | На хосте раннера                   |
| ------------------------------------------- | ---------------------------------- |
| `runners/gitea/config.example.yaml`         | `<runner-dir>/config.yaml`         |
| `runners/gitea/docker-compose.example.yaml` | `<runner-dir>/docker-compose.yaml` |
| `runners/gitea/.env.example`                | `<runner-dir>/.env`                |

## Деплой

Путь здесь устроен как `deploy/<способ доставки>/<профиль проекта>` и с путём
у потребителя не совпадает: набор `systemd/` ложится в `deploy/`, содержимое
`docker/` — в `docker/`, рядом с `Dockerfile`.

Наборов `systemd/` два, и у потребителя оба претендуют на один и тот же
`deploy/` — берётся тот, что подходит языку проекта, как `ci-dotnet.yml` и
`ci-python.yml` в docker-наборе. Имена файлов юнита и шаблона окружения
переименовываются вслед за именем службы: что на что заменить — в
[deploy.md](deploy.md).

| Здесь                                       | У потребителя                 |
| ------------------------------------------- | ----------------------------- |
| `deploy/systemd/dotnet/install.sh`          | `deploy/install.sh` — один из |
| `deploy/systemd/python/install.sh`          | `deploy/install.sh` — двух    |
| `deploy/systemd/dotnet/example-api.service` | `deploy/example-api.service`  |
| `deploy/systemd/python/example-api.service` | `deploy/example-api.service`  |
| `deploy/systemd/dotnet/api.env.example`     | `deploy/api.env.example`      |
| `deploy/systemd/python/api.env.example`     | `deploy/api.env.example`      |
| `deploy/docker/spa/nginx.conf`              | `docker/nginx.conf`           |

## Настройки проекта

Конфиги, которые читает инструмент сборки. Содержимое копируется без
изменений, а путь назначения из пути здесь не выводится — как в разделах
`deploy/` и `runners/`, его говорит строка `# место:` в шапке файла.

| Здесь                                             | У потребителя                         |
| ------------------------------------------------- | ------------------------------------- |
| `project/npm/.npmrc`                              | `.npmrc`                              |
| `project/npm/scripts/check-lockfile-resolved.mjs` | `scripts/check-lockfile-resolved.mjs` |

Зачем эти файлы и как подключается сторож — в [npm.md](npm.md).
