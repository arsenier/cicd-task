# Практика CI/CD

[![CI/CD](https://github.com/arsenier/cicd-task/actions/workflows/ci_cd.yml/badge.svg)](https://github.com/arsenier/cicd-task/actions/workflows/ci_cd.yml)

## Краткое описание

Данный репозиторий содержит результаты практической работы по настройке CI/CD конвейера для автоматического тестирования, сборки и развертывания приложения на облачном сервере.

## Начало работы

Склонировать репозиторий и перейти в директорию `blue_green`

```
git clone https://github.com/arsenier/cicd-task.git
cd cicd-task
```

В файле `scp_to_serv.sh` указать актуальные SSH-ключ и адрес сервера где необходимо развернуть приложение, после чего запустить скрипт (либо просто перекинуть все файлы в катало `/root/` на сервере)

```
./scp_to_serv.sh
```

Подключится к серверу по SSH и выполнить скрипты инициализации:

```
./server_init.sh
./bg_init.sh
```

После чего по адресу сервера должна быть доступна веб страница с развернутым приложением.

## Обновление приложения

Для обновления приложения реализован метод blue-green развертывания. Чтобы обновить приложение с помощью нового докер-образа достаточно выполнить скрипт `bg_switch.sh`

```
./bg_switch.sh
```

Скрипт проверяет цвет запущенного образа, пуллит новый образ с DockerHub, запускает его и переключает настройки nginx-прокси. После чего выключает старый цвет.

## Остановка сервера

Для остановки сервера нужно выполнить скрипт:

```
./bg_shutdown.sh
```

## Структура проекта

В качестве приложения для развертывания был взят пример Python-приложения из урока: https://www.youtube.com/watch?v=8gtEtEY0ofM

Ниже объясняется файловая структура, имеющая отношение непосредственно к CI/CD, игнорируя файлы самого приложения:

```
cicd-task/
├── .github/
│   └── workflows/
│       └── ci_cd.yml # Файл пайплайна CI/CD с использованием Github Actions
├── blue_green/ # Набор скриптов для Blue-Green развертывания приложения
│   ├── bg_init.sh
│   ├── bg_shutdown.sh
│   ├── bg_switch.sh
│   ├── docker-compose.yml
│   ├── scp_to_serv.sh
│   └── server_init.sh
├── nginx/ # Конфигурации nginx прокси для Blue-Green
│   ├── Dockerfile
│   ├── nginx_blue.conf
│   └── nginx_green.conf
...
```

## CI/CD

Файл пайплайна GitHub Actions `./.github/workflows/ci_cd.yml` описывает процесс CI/CD для проекта. Вот краткое описание его структуры и шагов:

### Основные компоненты:

1. **Имя и триггеры**:
   - Пайплайн называется `CI/CD`.
   - Он запускается при `push` в ветку `master` и может быть инициирован вручную через `workflow_dispatch`.

2. **Разрешения**:
   - Устанавливаются разрешения для чтения содержимого и записи токена идентификации.

3. **Работы (jobs)**:
   - **run_tests**:
     - Запускается на `ubuntu-latest`.
     - Шаги:
       - Проверка кода из репозитория.
       - Установка Python версии 3.12.
       - Установка утилиты `make`.
       - Запуск тестов с помощью команды `make test`.

   - **publish_image**:
     - Запускается на `ubuntu-latest` и зависит от успешного завершения `run_tests`.
     - Шаги:
       - Проверка кода из репозитория.
       - Вход в Docker Hub с использованием секретов.
       - Извлечение метаданных для Docker (теги, метки).
       - Сборка и публикация Docker-образа.

   - **publish_nginx**:
     - Запускается на `ubuntu-latest`.
     - Шаги аналогичны `publish_image`, но для Nginx-образа, с указанием контекста и Dockerfile для Nginx.

   - **deploy_application**:
     - Запускается на `ubuntu-latest` и зависит от успешного завершения `publish_image` и `publish_nginx`.
     - Шаги:
       - Вход на удаленный сервер через SSH и выполнение скрипта для развертывания образа.
<!-- 
### Закомментированные шаги:
Некоторые шаги, такие как генерация аттестации артефактов, закомментированы и не выполняются. -->

Этот файл пайплайна обеспечивает автоматизацию тестирования, сборки и развертывания приложения, что упрощает процесс CI/CD.

<!-- 
## CI

## CD

### Blue-Green

Файл пайплайна CI/CD, использующий GitHub Actions, описывает автоматизированный процесс интеграции и доставки программного обеспечения. Он состоит из нескольких ключевых компонентов, которые выполняются в ответ на определенные события, такие как коммиты в ветку `master`. Давайте разберем этот файл по частям.

## Основные компоненты файла

### 1. Определение пайплайна

```yaml
name: CI/CD

on:
    push:
      branches: [ "master" ]
```
Этот блок определяет имя пайплайна (`CI/CD`) и событие, при котором он будет запускаться — в данном случае это `push` в ветку `master`.

### 2. Права доступа

```yaml
permissions:
    contents: read
    id-token: write
```
Здесь устанавливаются права доступа для выполнения действий в рамках пайплайна. В данном случае разрешается чтение содержимого репозитория и запись токена идентификации.

### 3. Задание работ (jobs)

Пайплайн состоит из трех основных работ: `run_tests`, `publish_image` и `deploy_application`.

#### **run_tests**

```yaml
run_tests:
    runs-on: ubuntu-latest
```
Эта работа выполняется на последней версии Ubuntu. Она включает следующие шаги:

- **Проверка кода**:
  ```yaml
  - uses: actions/checkout@v4
  ```
  Этот шаг загружает код из репозитория.

- **Настройка Python**:
  ```yaml
  - name: Set up python 3.12
    uses: actions/setup-python@v3
    with:
        python-version: "3.12"
  ```
  Устанавливается версия Python для выполнения тестов.

- **Установка Make**:
  ```yaml
  - name: Set up make
    run: |
        sudo apt update
        sudo apt install -y make
  ```
  Устанавливается утилита Make, необходимая для запуска тестов.

- **Запуск тестов**:
  ```yaml
  - name: Run tests
    run: |
        make test
  ```
  Выполняются тесты, определенные в Makefile.

#### **publish_image**

```yaml
publish_image:
    name: Push Docker image to Docker Hub
    runs-on: ubuntu-latest
    needs: run_tests
```
Эта работа зависит от успешного завершения работы `run_tests`. Она отвечает за публикацию Docker-образа:

- **Логин в Docker Hub**:
  ```yaml
  - name: Log in to Docker Hub
    uses: docker/login-action@f4ef78c080cd8ba55a85445d5b36e214a81df20a
    with:
        username: ${{ secrets.DOCKER_LOGIN }}
        password: ${{ secrets.DOCKER_PASS }}
  ```
  Здесь происходит аутентификация на Docker Hub с использованием секретов для безопасного хранения логина и пароля.

- **Извлечение метаданных**:
  ```yaml
  - name: Extract metadata (tags, labels) for Docker
    id: meta
    uses: docker/metadata-action@9ec57ed1fcdbf14dcef7dfbe97b2010124a938b7
    with:
        images: arsenier/cicd-task
  ```
  Этот шаг извлекает метаданные для образа Docker, такие как теги и метки.

- **Сборка и публикация Docker-образа**:
  ```yaml
  - name: Build and push Docker image
    id: push
    uses: docker/build-push-action@3b5e8027fcad23fda98b2e3ac259d8d67585f671
    with:
        context: .
        file: ./build/Dockerfile
        push: true
        tags: ${{ steps.meta.outputs.tags }}
        labels: ${{ steps.meta.outputs.labels }}
  ```
  Здесь происходит сборка образа по указанному Dockerfile и его публикация в Docker Hub с использованием ранее извлеченных тегов и меток.

#### **deploy_application**

```yaml
deploy_application:
    name: Deploy application on the remote server
    runs-on: ubuntu-latest
    needs: publish_image
```
Эта работа выполняется после успешной публикации образа. Она отвечает за развертывание приложения на удаленном сервере:

- **Деплой через SSH**:
  ```yaml
  - name: Log into the server via SSH and deploy image
    uses: appleboy/ssh-action@v1.2.0
    with:
      host: ${{ secrets.SELECTEL_SERVER_IP }}
      username: ${{ secrets.SELECTEL_SERVER_USER }}
      key: ${{ secrets.SELECTEL_PRIVATE_SSH_KEY }}
      script: |
          docker ps -aq | xargs docker stop | xargs docker rm
          docker run --pull=always -d -p 5000:5000 arsenier/cicd-task:master
  ```
  Этот шаг выполняет вход на удаленный сервер по SSH и разворачивает контейнер с приложением, останавливая и удаляя старые контейнеры перед запуском нового. -->



<!-- ## Заключение

Данный файл пайплайна CI/CD демонстрирует автоматизацию процессов тестирования, сборки и развертывания приложения с использованием GitHub Actions. Он позволяет разработчикам быстро интегрировать изменения и обеспечивать надежное развертывание обновлений на продакшн-сервере.

Citations:
[1] https://graphite.dev/guides/introduction-to-github-actions-for-ci-cd-pipelines
[2] https://900913.ru/tldr/common/
[3] https://dev.to/snehalkadwe/a-guide-to-cicd-pipelines-using-github-action-5doj
[4] https://github.blog/enterprise-software/ci-cd/build-ci-cd-pipeline-github-actions-four-steps/
[5] https://www.youtube.com/watch?v=ciqWMIf7Pz0 -->
