#!/bin/sh
# источник: nii-energomash/automation/deploy/systemd/dotnet/install.sh
# место: deploy/install.sh
#
# Установка и обновление службы .NET-сервиса. Вариант для python-сервиса —
# в соседнем каталоге python/; у потребителя оба ложатся в один и тот же
# deploy/install.sh, поэтому берётся один. Что переименовать под свой проект —
# в docs/deploy.md.
#
# Запускается из распакованного релизного архива:
#
#   tar -xzf Example.Api-<версия>-linux-x64.tar.gz
#   cd Example.Api-<версия>-linux-x64
#   sudo ./deploy/install.sh
#
# Что именно делать, скрипт определяет по наличию установленного юнита.
#
# Первая установка: заводит пользователя службы, разворачивает каталог, кладёт
# шаблон файла окружения и юнит. Службу не запускает — сначала в файл окружения
# нужно вписать пароль базы.
#
# Обновление: останавливает службу, заменяет каталог, восстанавливает права,
# запускает обратно. Файл окружения не трогает — настройки и пароль остаются.
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

CONFIG="$CONFIG_DIR/api.env"
UNIT="/etc/systemd/system/$SERVICE.service"

die() {
    echo "$*" >&2
    exit 1
}

require_root() {
    [ "$(id -u)" = 0 ] || die "Требуются права root: sudo ./deploy/install.sh"
}

resolve_source() {
    SOURCE=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
}

check_source() {
    [ -f "$SOURCE/Example.Api.dll" ] || die "В $SOURCE нет Example.Api.dll — это не вывод publish"
    [ -e "$SOURCE/Example.Api" ] || die "В $SOURCE нет исполняемого файла Example.Api"
    [ -f "$SOURCE/deploy/$SERVICE.service" ] || die "В $SOURCE нет deploy/$SERVICE.service"
    [ -f "$SOURCE/deploy/api.env.example" ] || die "В $SOURCE нет deploy/api.env.example"
}

# Каталог назначения сносится целиком, поэтому проверяется, что это именно
# установка сервиса, а не посторонний путь из опечатки в EXAMPLE_API_DIR.
check_target() {
    [ -e "$TARGET" ] || return 0
    [ -d "$TARGET" ] || die "$TARGET существует и не является каталогом"
    [ -e "$TARGET/Example.Api" ] || die "В $TARGET нет Example.Api — похоже, это не установка сервиса"
}

detect_mode() {
    if [ -f "$UNIT" ]; then
        MODE=update
    else
        MODE=install
    fi
    echo "Режим: $MODE. Источник: $SOURCE"
}

# Пароль учётной записи не задаётся: useradd --system создаёт её заблокированной,
# входить под ней некуда и незачем. Процесс запускает systemd директивой User=.
ensure_user() {
    id "$OWNER" >/dev/null 2>&1 && return 0
    [ "$MODE" = install ] || die "Пользователь $OWNER не найден, хотя служба установлена"

    shell=/usr/sbin/nologin
    [ -x "$shell" ] || shell=/bin/false
    useradd --system --no-create-home --shell "$shell" "$OWNER"
    echo "Заведён пользователь $OWNER"
}

stop_service() {
    [ "$MODE" = update ] || return 0
    systemctl stop "$SERVICE"
}

replace_target() {
    rm -rf "$TARGET"
    mkdir -p "$TARGET"

    # cp -a, а не rsync: последнего может не быть в минимальной установке.
    cp -a "$SOURCE/." "$TARGET/"

    # Владелец root, группа службы: процессу довольно чтения и выполнения. Право
    # записи в собственные файлы дало бы скомпрометированному сервису
    # возможность подменить свои же бинарники.
    chown -R "root:$OWNER" "$TARGET"

    # Релизные архивы бит исполнения сохраняют — это tar. Проверка на случай,
    # что архив перепаковали по дороге средством, которое прав не хранит.
    chmod +x "$TARGET/Example.Api"
}

# Существующий файл не трогается: в нём пароль базы и настройки машины.
ensure_config() {
    FRESH_CONFIG=no
    [ -f "$CONFIG" ] && return 0

    mkdir -p "$CONFIG_DIR"
    cp "$SOURCE/deploy/api.env.example" "$CONFIG"
    chown "root:$OWNER" "$CONFIG"
    chmod 640 "$CONFIG"
    FRESH_CONFIG=yes
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

# Пустой шаблон запускать бессмысленно: без строки подключения служба не
# стартует. Поэтому со свежей конфигурацией скрипт останавливается.
start_service() {
    if [ "$FRESH_CONFIG" = yes ]; then
        echo
        echo "Осталось два шага:"
        echo "  1. Заполнить $CONFIG — как минимум строку подключения к базе."
        echo "  2. systemctl enable --now $SERVICE"
        return 0
    fi

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
    check_target
    detect_mode

    ensure_user
    stop_service
    replace_target
    ensure_config
    ensure_unit
    start_service
}

main
