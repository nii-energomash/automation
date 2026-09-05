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

## GitHub

Сегмент типа проекта при копировании выбрасывается.

| Здесь                                        | У потребителя                   |
| -------------------------------------------- | ------------------------------- |
| `ci-src/.github/workflows/npm/ci.yml`        | `.github/workflows/ci.yml`      |
| `ci-src/.github/workflows/npm/publish.yml`   | `.github/workflows/publish.yml` |
| `ci-src/.github/workflows/nuget/ci.yml`      | `.github/workflows/ci.yml`      |
| `ci-src/.github/workflows/nuget/publish.yml` | `.github/workflows/publish.yml` |

Релизные модели наборов — в [npm.md](npm.md) и [nuget.md](nuget.md).

## Gitea

| Здесь                                       | У потребителя                  |
| ------------------------------------------- | ------------------------------ |
| `ci-src/.gitea/workflows/npm/ci.yml`        | `.gitea/workflows/ci.yml`      |
| `ci-src/.gitea/workflows/npm/publish.yml`   | `.gitea/workflows/publish.yml` |
| `ci-src/.gitea/workflows/nuget/ci.yml`      | `.gitea/workflows/ci.yml`      |
| `ci-src/.gitea/workflows/nuget/publish.yml` | `.gitea/workflows/publish.yml` |

Чем gitea-вариант отличается от github-варианта — в [npm.md](npm.md) и
[nuget.md](nuget.md).

## Конфиги и деплой

Пока пусто.
