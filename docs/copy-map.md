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

## Конфиги и деплой

Пока пусто.
