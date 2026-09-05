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

Пока пусто.

## Gitea

Пока пусто.

## Конфиги и деплой

Пока пусто.
