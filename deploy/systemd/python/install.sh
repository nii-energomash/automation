#!/bin/sh
# источник: nii-energomash/automation/deploy/systemd/python/install.sh
# место: deploy/install.sh
#
# Установка и обновление службы python-сервиса. Вариант для .NET-сервиса —
# в соседнем каталоге dotnet/; у потребителя оба ложатся в один и тот же
# deploy/install.sh, поэтому берётся один. Что переименовать под свой проект —
# в docs/deploy.md.
#
# Запускается из распакованного релизного архива:
#
#   tar -xzf example-api-<версия>.tar.gz
#   cd example-api-<версия>
#   sudo ./deploy/install.sh
#
# Из клона репозитория работает так же — версия сервиса при этом останется
# 0.0.0-dev, потому что файл src/API_VERSION заполняется при сборке релиза.
#
# Что именно делать, скрипт определяет по наличию установленного юнита.
#
# Первая установка: заводит пользователя службы, разворачивает каталог, создаёт
# виртуальное окружение, кладёт шаблон файла окружения и юнит, запускает службу.
#
# Обновление: останавливает службу, заменяет код, при необходимости пересобирает
# окружение, запускает обратно. Файл окружения не трогает — настройки остаются.
#
# Версии скрипт не знает и не проверяет: он ставит каталог, в котором лежит сам.
#
# Порядок шагов — в main в конце файла. Всё, что проверяет, идёт до всего, что
# меняет: упасть на полпути, оставив службу погашенной, хуже, чем не начинать.

set -eu

SERVICE=${EXAMPLE_API_SERVICE:-example-api}
TARGET=${EXAMPLE_API_DIR:-/opt/example/api}
OWNER=${EXAMPLE_API_USER:-example}
CONFIG_DIR=${EXAMPLE_API_CONFIG_DIR:-/etc/example}
PYTHON=${EXAMPLE_API_PYTHON:-python3.11}

CONFIG="$CONFIG_DIR/api.env"
UNIT="/etc/systemd/system/$SERVICE.service"
VENV="$TARGET/.venv"
LOCK=requirements-astra.txt

# Содержимое каталога установки: всё, что нужно службе, и текст условий
# распространения. Список явный, а не «весь каталог целиком», потому что
# источником может быть клон репозитория — оснастке команды в /opt делать
# нечего.
PAYLOAD="src $LOCK deploy LICENSE"

die() {
    echo "$*" >&2
    exit 1
}

require_root() {
    [ "$(id -u)" = 0 ] || die "Требуются права root: sudo ./deploy/install.sh"
}

resolve_source() {
    SOURCE=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
}

check_source() {
    for item in $PAYLOAD; do
        [ -e "$SOURCE/$item" ] || die "В $SOURCE нет $item — это не дерево сервиса"
    done

    [ -f "$SOURCE/src/run_waitress.py" ] || die "В $SOURCE нет src/run_waitress.py"
    [ -f "$SOURCE/src/main.py" ] || die "В $SOURCE нет src/main.py"
    [ -f "$SOURCE/deploy/$SERVICE.service" ] || die "В $SOURCE нет deploy/$SERVICE.service"
    [ -f "$SOURCE/deploy/api.env.example" ] || die "В $SOURCE нет deploy/api.env.example"
}

# Системный интерпретатор Astra Linux 1.7 — 3.7, а сервис работает на 3.11.
# Модуль venv в Debian и Astra лежит отдельным пакетом, и его отсутствие
# выясняется только при попытке создать окружение.
check_python() {
    command -v "$PYTHON" >/dev/null \
        || die "Не найден $PYTHON. Установите: apt install python3.11 python3.11-venv"
    "$PYTHON" -m venv --help >/dev/null 2>&1 \
        || die "У $PYTHON нет модуля venv. Установите: apt install python3.11-venv"
}

# Содержимое каталога назначения сносится, поэтому проверяется, что это именно
# установка сервиса, а не посторонний путь из опечатки в EXAMPLE_API_DIR.
check_target() {
    [ -e "$TARGET" ] || return 0
    [ -d "$TARGET" ] || die "$TARGET существует и не является каталогом"
    [ -e "$TARGET/src/run_waitress.py" ] || [ -d "$VENV" ] \
        || die "В $TARGET нет ни src/run_waitress.py, ни .venv — похоже, это не установка сервиса"
}

detect_mode() {
    if [ -f "$UNIT" ]; then
        MODE=update
    else
        MODE=install
    fi
    echo "Режим: $MODE. Источник: $SOURCE"
}

# Решение принимается до замены файлов: сравнивается lock-файл новой версии с
# тем, по которому собрано установленное окружение. Совпали — окружение
# остаётся, и обновление обходится без похода в PyPI.
detect_venv_rebuild() {
    if [ ! -x "$VENV/bin/python" ]; then
        VENV_REBUILD=yes
    elif cmp -s "$SOURCE/$LOCK" "$TARGET/$LOCK"; then
        VENV_REBUILD=no
        echo "Набор пакетов не изменился, окружение сохраняется"
    else
        VENV_REBUILD=yes
        echo "Набор пакетов изменился, окружение будет пересобрано"
    fi
}

# Пароль учётной записи не задаётся: useradd --system создаёт её заблокированной,
# входить под ней некуда и незачем. Процесс запускает systemd директивой User=.
#
# Группа заводится явно, а не полагаясь на USERGROUPS_ENAB в login.defs. Обе
# проверки идемпотентны: учётная запись службы может быть одна на весь комплекс,
# и завести её мог установщик другого компонента.
ensure_user() {
    if ! getent group "$OWNER" >/dev/null; then
        [ "$MODE" = install ] || die "Группа $OWNER не найдена, хотя служба установлена"
        groupadd --system "$OWNER"
        echo "Заведена группа $OWNER"
    fi

    id "$OWNER" >/dev/null 2>&1 && return 0
    [ "$MODE" = install ] || die "Пользователь $OWNER не найден, хотя служба установлена"

    shell=/usr/sbin/nologin
    [ -x "$shell" ] || shell=/bin/false
    useradd --system --no-create-home --shell "$shell" --gid "$OWNER" "$OWNER"
    echo "Заведён пользователь $OWNER"
}

stop_service() {
    [ "$MODE" = update ] || return 0
    systemctl stop "$SERVICE"
}

# Виртуальное окружение переживает замену, когда пересобирать его не нужно,
# поэтому каталог сносится не целиком.
replace_target() {
    mkdir -p "$TARGET"
    find "$TARGET" -mindepth 1 -maxdepth 1 ! -name .venv -exec rm -rf {} +

    for item in $PAYLOAD; do
        # cp -a, а не rsync: последнего может не быть в минимальной установке.
        cp -a "$SOURCE/$item" "$TARGET/"
    done

    # Кэш байт-кода мог приехать из клона разработчика: он собран другим
    # интерпретатором и другому каталогу не годится.
    find "$TARGET/src" -name __pycache__ -type d -prune -exec rm -rf {} +
}

ensure_venv() {
    [ "$VENV_REBUILD" = yes ] || return 0

    rm -rf "$VENV"
    "$PYTHON" -m venv "$VENV"

    # Пакеты ставятся строго по lock-файлу. Адрес зеркала, если оно поднято в
    # контуре, задаётся переменной PIP_INDEX_URL — она наследуется от вызова и в
    # самих файлах зависимостей ничего не меняет.
    "$VENV/bin/pip" install --no-input --disable-pip-version-check -r "$TARGET/$LOCK"
}

# Байт-код прогревается заранее и от root: каталог установки службе недоступен
# на запись, и сама она __pycache__ не создаст — молча, без ошибки, но и без
# кэша.
warm_bytecode() {
    "$VENV/bin/python" -m compileall -q "$TARGET/src" >/dev/null
}

# Владелец root, группа службы: процессу довольно чтения и выполнения. Право
# записи в собственные файлы дало бы скомпрометированному сервису возможность
# подменить свой же код.
set_permissions() {
    chown -R "root:$OWNER" "$TARGET"
    chmod -R go-w "$TARGET"
}

# Существующий файл не трогается: в нём настройки этой машины.
ensure_config() {
    [ -f "$CONFIG" ] && return 0

    mkdir -p "$CONFIG_DIR"
    cp "$SOURCE/deploy/api.env.example" "$CONFIG"
    chown "root:$OWNER" "$CONFIG"
    chmod 640 "$CONFIG"
    echo "Положен шаблон $CONFIG"
}

# Установленный юнит мог быть правлен под машину, поэтому он не
# перезаписывается молча.
ensure_unit() {
    if [ ! -f "$UNIT" ]; then
        cp "$SOURCE/deploy/$SERVICE.service" "$UNIT"
        systemctl daemon-reload
        echo "Установлен юнит $UNIT"
    elif ! cmp -s "$SOURCE/deploy/$SERVICE.service" "$UNIT"; then
        echo "ВНИМАНИЕ: $UNIT отличается от юнита новой версии." >&2
        echo "          Сравните: diff $UNIT $TARGET/deploy/$SERVICE.service" >&2
    fi
}

# Обязательных значений в файле окружения нет, поэтому служба запускается сразу:
# на умолчаниях она работоспособна, а править нужно лишь то, что на этой машине
# отличается.
start_service() {
    if [ "$MODE" = install ]; then
        systemctl enable --now "$SERVICE"
    else
        systemctl start "$SERVICE"
    fi

    systemctl --no-pager status "$SERVICE"
}

main() {
    require_root
    resolve_source
    check_source
    check_python
    check_target
    detect_mode
    detect_venv_rebuild

    ensure_user
    stop_service
    replace_target
    ensure_venv
    warm_bytecode
    set_permissions
    ensure_config
    ensure_unit
    start_service
}

main
