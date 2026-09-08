# источник: nii-energomash/automation/deploy/docker/python/Dockerfile
# место: Dockerfile
#
# Образ python-сервиса. Второй вариант набора —
# deploy/docker/dotnet/Dockerfile, берётся тот, что подходит языку проекта.
# Что принимает сборка и откуда это приходит — в docs/docker.md, что заменить
# под свой проект — в docs/deploy.md.

FROM python:3.11-slim

# Вывод не буферизуется: иначе логи сервиса появляются в docker logs пачками
# или теряются при остановке контейнера.
ENV PYTHONUNBUFFERED=1

WORKDIR /app

# Зависимости ставятся отдельным слоем и раньше исходников: правка кода не
# должна пересобирать набор пакетов. Строго по lock-файлу целевой машины,
# отдельные пакеты руками не добираются.
#
# Имя lock-файла — проектная часть: у проекта их может быть несколько, по
# одному на целевое окружение, и в образ едет файл целевой машины.
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

# Передача образа есть распространение, поэтому тексты лицензий должны в нём
# присутствовать. Три источника, ни один не заменяет другой:
#
#   /usr/share/doc/<пакет>/copyright  — слой Debian, приезжает сам (slim
#                                       сохраняет copyright явным правилом);
#   <пакет>.dist-info                 — то, что положил в wheel сам автор;
#   /licenses                         — наш набор, каталог по конвенции.
#
# Третий источник обязателен: wheel с текстом лицензии приходит не всегда.
# Пакет, у которого в dist-info только поле License-Expression, а самого текста
# нет, без нашего каталога оставил бы обязательство по нему незакрытым.
#
# Вычищать что-либо из перечисленного нельзя — ни ради размера, ни заодно.
# Раскладка сохраняется: THIRD-PARTY-NOTICES.md ссылается на тексты
# относительными путями, и без вложенного каталога ссылки порвались бы.
COPY LICENSE /licenses/
COPY THIRD-PARTY-NOTICES.md /licenses/
COPY third-party-licenses/ /licenses/third-party-licenses/

# Содержимое src кладётся плоско: main.py импортирует соседние пакеты без
# префикса, корнем импортов служит src. Файл API_VERSION приезжает вместе с
# ними, и сервис находит его в рабочем каталоге.
COPY src/ ./

# Версия для сборки. Пустое значение переменной ложно, и сервис проваливается
# на файл API_VERSION; заданное — перекрывает его. При запуске контейнера
# перекрыть можно ещё раз, через -e.
ARG API_VERSION=""
ENV API_VERSION=$API_VERSION

RUN useradd --system --no-create-home app
USER app

# Значение по умолчанию объявлено переменной, а не только в коде: его видно в
# docker inspect, и на него опирается проверка состояния ниже.
ENV PORT=5020
EXPOSE 5020

# Проверка состояния опрашивает тот же маршрут /health, что и внешний
# мониторинг, и выставляет статус контейнера для docker ps и для
# depends_on: condition: service_healthy в compose. Запрос идёт python'ом:
# curl и wget в slim-образе отсутствуют, а тянуть их ради проверки незачем.
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
    CMD ["python", "-c", "import os, urllib.request; urllib.request.urlopen('http://127.0.0.1:' + os.environ['PORT'] + '/health')"]

CMD ["python", "run_waitress.py"]
