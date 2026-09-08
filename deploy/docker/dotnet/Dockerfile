# syntax=docker/dockerfile:1

# источник: nii-energomash/automation/deploy/docker/dotnet/Dockerfile
# место: Dockerfile
#
# Директива syntax обязана оставаться первой строкой файла: после комментария
# она сама становится комментарием и молча перестаёт работать.
#
# Образ .NET-сервиса. Второй вариант набора — deploy/docker/python/Dockerfile,
# берётся тот, что подходит языку проекта. Что принимает сборка и откуда это
# приходит — в docs/docker.md, что заменить под свой проект — в docs/deploy.md.

# Сборка выполняется целиком внутри образа, а не на раннере с копированием
# готового вывода: иначе `docker build .` сам по себе сервис не собирает, и
# образ становится придатком одного конкретного пайплайна.
FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build

WORKDIR /src

# Список источников пакетов приходит параметром: на площадке GitHub это
# nuget.config из корня репозитория, на второй его собирает под реестр Gitea
# раннер. Внутри образа файл в любом случае называется nuget.config — так его
# находит восстановление, и --configfile не нужен.
ARG NUGET_CONFIG=nuget.config

# Файлы проектов копируются раньше исходников: правка кода не должна
# пересобирать граф зависимостей. Вместе с ними едут Directory.*.props и список
# источников — без первых восстановление не увидит версий пакетов (они заданы
# централизованно), без второго не увидит источников.
#
# Сам перечень csproj — проектная часть: строк здесь ровно столько, сколько
# проектов в решении. Обобщению он не поддаётся, обобщается порядок шагов.
COPY ${NUGET_CONFIG} ./nuget.config
COPY Directory.Build.props Directory.Packages.props ./
COPY src/Example.Api/Example.Api.csproj       src/Example.Api/
COPY src/Example.Domain/Example.Domain.csproj src/Example.Domain/
COPY src/Example.Tools/Example.Tools.csproj   src/Example.Tools/

# Реестр не отдаёт пакеты анонимно, даже публичные. Токен подтверждает личность
# пользователя, а не выдаёт доступ, — потому на GitHub одного classic PAT со
# scope read:packages хватает на оба скоупа.
#
# Приезжает он секретом BuildKit, а не аргументом сборки: ARG остался бы в
# `docker history` готового образа. Площадку имя секрета не называет — её знает
# только список источников, поэтому токен выставляется сразу под обоими
# именами, на которые тот может сослаться.
#
# Пустой файл вместо секрета BuildKit подставляет молча, поэтому проверка явная:
# иначе NuGet отправит в заголовок литерал вида %GH_PACKAGES_TOKEN% и ответит
# 401 без намёка на причину.
RUN --mount=type=secret,id=packages_token \
    if [ ! -s /run/secrets/packages_token ]; then \
      echo 'Не передан секрет packages_token; нужен токен с правом чтения пакетов' >&2; \
      exit 1; \
    fi; \
    PACKAGES_TOKEN="$(cat /run/secrets/packages_token)"; \
    GH_PACKAGES_TOKEN="$PACKAGES_TOKEN" \
    GT_PACKAGES_TOKEN="$PACKAGES_TOKEN" \
    dotnet restore src/Example.Api/Example.Api.csproj

COPY src/ src/

# Версия задаётся сборкой, в исходниках её нет. Значение вида 0.0.0-sha-1234567
# допустимо: MSBuild режет Version по первому дефису на VersionPrefix и
# VersionSuffix.
ARG API_VERSION=0.0.0

RUN dotnet publish src/Example.Api/Example.Api.csproj \
    --configuration Release \
    --no-restore \
    -p:Version=$API_VERSION \
    --output /app/publish


FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS runtime

WORKDIR /app

# Передача образа есть распространение: внутри едут чужие сборки, поэтому тексты
# лицензий обязаны лежать в нём. Каталог /licenses — конвенция.
COPY LICENSE THIRD-PARTY-NOTICES.md /licenses/

COPY --from=build /app/publish ./

# Serilog пишет в файл, и вне контейнера это правильно — конфигурация сервиса
# рассчитана в том числе на запуск без docker. Здесь переопределяется только
# путь: в appsettings.json он задан относительно рабочего каталога процесса
# (`../../logs`), что верно для запуска из исходников и бессмысленно тут.
#
# Основным каналом остаётся stdout: SetupLogging добавляет Serilog провайдером,
# а не заменяет конвейер, поэтому штатный Console-провайдер на месте и docker
# видит логи без всяких настроек. Файлы — дубль; без примонтированного тома они
# эфемерны и ограничены сами собой (File sink по умолчанию держит 31 файл).
RUN mkdir /logs && chown $APP_UID:$APP_UID /logs

ENV Serilog__WriteTo__0__Args__path=/logs/Example.Api-.txt

# Без этой переменной сервис в контейнере недостижим снаружи: в appsettings.json
# Kestrel прибит к 127.0.0.1, а конфигурация Kestrel:Endpoints перекрывает и
# ASPNETCORE_URLS, и ASPNETCORE_HTTP_PORTS базового образа — задать порт их
# средствами нельзя, перекрыть можно только тем же ключом конфигурации.
ENV Kestrel__Endpoints__Http__Url=http://+:5005

EXPOSE 5005

# HEALTHCHECK здесь намеренно нет. Директива запускает команду внутри
# контейнера, а в aspnet-образе нет ни curl, ни wget; ставить их ради поля
# статуса, на которое никто не завязан, незачем. Живость проверяется снаружи
# запросом /health — тем же путём, что и остальные конечные точки.

# Пользователь app и переменная APP_UID приходят из базового образа .NET.
USER $APP_UID

ENTRYPOINT ["dotnet", "Example.Api.dll"]
