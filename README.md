# automation

Переиспользуемые workflows и actions для CI/CD npm-проектов на двух площадках:
GitHub Actions и Gitea Actions.

Репозиторий подключается из проекта-потребителя: воркфлоу вызываются через
`uses:`, отдельные действия — внутри собственных воркфлоу.

## Как подключать

GitHub:

```yaml
jobs:
  ci:
    uses: nii-energomash/automation/.github/workflows/npm-ci.yml@v1
    with:
      node-version: "20"
    secrets:
      node-auth-token: ${{ secrets.GH_PACKAGES_TOKEN }}
```

Gitea — то же самое, но ссылка абсолютная и указывает на установку Gitea:

```yaml
jobs:
  ci:
    uses: https://<gitea-host>/<owner>/automation/.gitea/workflows/npm-ci.yml@v1
```

Конкретный адрес совпадает с тем, что стоит в `uses:` файлов
`.gitea/workflows/**`: параметризовать эту строку нельзя (см. «Ограничения»).

Ссылаться следует на `@v1`, а не на `@master`.

## Версионирование

- `master` — ветка разработки. Контракт входов здесь меняется без
  предупреждения, ссылаться на неё из проектов не следует.
- `vN` — релизная ветка. Внутри мажора контракт совместим: входы не удаляются,
  умолчания и семантика существующих входов не меняются.
- `vN.M.P` — неизменяемый тег. Ссылка `@vN` отслеживает ветку и получает
  исправления, ссылка `@vN.M.P` фиксирует состояние намертво.

Мажор поднимается, если удалён вход, изменено умолчание или изменилась
семантика существующего входа. Добавление входа с умолчанием, равным прежнему
поведению, — минор.

Примеры в `examples/**` внутри релизной ветки ссылаются на `@v1`, внутри
`master` — на `@master`. Копировать следует из релизной ветки.

## Что здесь есть

### Воркфлоу для GitHub — `.github/workflows`

| Файл | Назначение |
| --- | --- |
| [npm-ci.yml](.github/workflows/npm-ci.yml) | Линт, тесты, сборка; по флагу — публикация каталога сборки как артефакта |
| [npm-package-publish.yml](.github/workflows/npm-package-publish.yml) | Сборка и публикация npm-пакета по git-тегу `v*.*.*` |
| [npm-docker-publish.yml](.github/workflows/npm-docker-publish.yml) | Сборка и публикация docker-образа: релиз по тегу, технический тег по push, повторная публикация вручную |
| [docker-cleanup.yml](.github/workflows/docker-cleanup.yml) | Удаление образов с техническими тегами старше указанного возраста |

### Воркфлоу для Gitea — `.gitea/workflows`

| Файл | Назначение |
| --- | --- |
| [npm-ci.yml](.gitea/workflows/npm-ci.yml) | Линт, тесты, сборка |
| [npm-ci-for-mirror.yml](.gitea/workflows/npm-ci-for-mirror.yml) | То же, но проект собирается только на зеркальных пакетах из реестра Gitea |
| [npm-package-publish.yml](.gitea/workflows/npm-package-publish.yml) | Сборка и публикация npm-пакета по git-тегу `v*.*.*` |

### Действия — `.github/actions`

| Каталог | Назначение |
| --- | --- |
| [docker-cleanup](.github/actions/docker-cleanup) | Удаление версий пакета с образами по префиксу тега и возрасту |
| [npm-registries-configure](.github/actions/npm-registries-configure) | Запись scope, адресов реестров и токена в `~/.npmrc` |
| [npm-setup-package-version-from-tag](.github/actions/npm-setup-package-version-from-tag) | Установка версии пакета из git-тега |
| [resolve-context](.github/actions/resolve-context) | Определение контекста вызова: режим, тег, ref |
| [resolve-tag-from-ref](.github/actions/resolve-tag-from-ref) | Извлечение git-тега из git-ref |
| [resolve-tag-to-ref](.github/actions/resolve-tag-to-ref) | Получение git-ref по git-тегу |
| [validate-ref-on-master](.github/actions/validate-ref-on-master) | Проверка, что ref находится в базовой ветке |
| [validate-tag-format](.github/actions/validate-tag-format) | Проверка формата тега `v*.*.*` |

### Действия — `.gitea/actions`

| Каталог | Назначение |
| --- | --- |
| [npm-registries-configure](.gitea/actions/npm-registries-configure) | То же, что github-вариант, с настройкой `strict-ssl` для реестра во внутренней сети |

Входы каждого воркфлоу и действия описаны в `description:` соответствующего
файла — здесь они не дублируются.

## Что завести у потребителя

Секреты:

| Имя | Где нужен |
| --- | --- |
| `GH_PACKAGES_TOKEN` | GitHub: чтение и публикация пакетов npm |
| `GT_PACKAGES_TOKEN` | Gitea: чтение и публикация пакетов npm |
| `GITHUB_TOKEN` | Встроенный; годится для docker-образа, привязанного к своему же репозиторию |

Встроенный `GITHUB_TOKEN` не отдаёт пакет, связанный с другим репозиторием, —
для зависимостей из приватного scope нужен PAT. Gitea автоматического токена
не выдаёт вовсе.

Переменные (`vars`), которые используют примеры:

| Имя | Значение |
| --- | --- |
| `NPM_SCOPE` | Основной scope пакетов, без `@` |
| `NPM_ORG_SCOPE` | Дополнительный scope, если пакеты лежат в двух |
| `NPM_REGISTRY_URL` | Адрес реестра npm |

Рабочие образцы вызовов — в [examples](examples): по каталогу на площадку
и схему публикации.

## Ограничения площадок

- Выражения в `uses:` не раскрываются: владелец, путь и ref остаются
  литералами. Ни `vars`, ни `inputs`, ни `env` там не работают — адрес Gitea
  и ref приходится править текстом.
- В `jobs.<job_id>.with` доступны только контексты `github`, `needs`,
  `strategy`, `matrix`, `inputs`, `vars`: пробросить значение через
  workflow-level `env:` в вызов переиспользуемого воркфлоу нельзя.
- Синтаксис `$/` для ссылки на собственный репозиторий работает только на
  github.com, поэтому здесь не используется.
- Переменные `vars` внутри переиспользуемого воркфлоу читаются у потребителя,
  а не у этого репозитория. Поэтому воркфлоу принимают `inputs`, а `vars`
  встречаются только в примерах.

## Лицензия

[MIT](LICENSE)
