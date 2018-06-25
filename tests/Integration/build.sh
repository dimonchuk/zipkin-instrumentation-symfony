#!/usr/bin/env bash

APP_FOLDER=test-app
SYMFONY_VERSION=$1

if [[ -z "$2" ]]; then
    ZIPKIN_INSTRUMENTATION_SYMFONY_VERSION=dev-master
else
    ZIPKIN_INSTRUMENTATION_SYMFONY_VERSION=$2
fi

# Deletes old executions of the build
rm -rf ${APP_FOLDER}

composer create-project symfony/website-skeleton:${SYMFONY_VERSION} ${APP_FOLDER} || exit 1
cd ${APP_FOLDER}

# Includes zipkin-instrumentation-symfony to the composer.json of the app
mv composer.json composer.json.dist
cat composer.json.dist \
| jq '.scripts["sync"] = ["rsync -arv --exclude=.git --exclude=tests/Integration --exclude=composer.lock --exclude=vendor ../../../ .zipkin-instrumentation-symfony"]' \
| jq '.scripts["pre-install-cmd"] = ["@sync"]' \
| jq '.scripts["pre-update-cmd"] = ["@sync"]' \
| jq --arg v "$ZIPKIN_INSTRUMENTATION_SYMFONY_VERSION" '.require["jcchavezs/zipkin-instrumentation-symfony"] = $v' \
| jq '.repositories = [{"type": "path","url": "./.zipkin-instrumentation-symfony/","options": {"symlink": true}}]' > composer.json

rm composer.lock

composer require symfony/web-server-bundle --dev

# includes configuration files to run the middleware in the app
cp ../tracing.yaml ./config/tracing.yaml
cp ../HealthController.php ./src/Controller
mv ./config/services.yaml ./config/services.yaml.dist
echo "imports: [{ resource: tracing.yaml }]" > ./config/services.yaml
cat ./config/services.yaml.dist >> ./config/services.yaml
