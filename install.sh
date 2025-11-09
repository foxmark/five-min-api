#!/bin/bash

if [[ ! -d "app" ]]; then
  mkdir app
fi

source .env
docker compose up -d

echo -e "run: docker compose exec php symfony new . --no-git --version=\"lts\" (press any key)"
read s1
docker compose exec php symfony new . --no-git --version="lts"

echo -e "run: compose exec php symfony composer require --dev symfony/maker-bundle (press any key)"
read s2
docker compose exec php symfony composer require --dev symfony/maker-bundle

echo -e "run: docker compose exec php symfony composer require --dev symfony/profiler-pack symfony/debug-bundle symfony/test-pack (press any key)"
read q3

docker compose exec php symfony composer require --dev symfony/profiler-pack symfony/debug-bundle symfony/test-pack

echo -e "run: compose exec php symfony composer require symfony/orm-pack --no-interaction --no-scripts (press any key)"
read q4

docker compose exec php symfony composer require symfony/orm-pack --no-interaction --no-scripts

echo -e "run: compose exec php symfony composer require --dev doctrine/doctrine-fixtures-bundle (press any key)"
read q5
docker compose exec php symfony composer require --dev doctrine/doctrine-fixtures-bundle

echo -e '------[ 🪄 this is where the magic happens 🎩 ]------'
echo -e "run: docker compose exec php symfony composer require api (press any key)"
read q6
docker compose exec php symfony composer require api

echo -e "Do you want create new database for the project? (y/n): "
read q7

if [[ "$q7" == "y" || "$q7" == "yes" ]]; then
    docker compose exec php symfony console doctrine:database:create
    echo -e ' '
fi

echo -e "Do you want install security packages? (y/n): "
read q8

if [[ "$q8" == "y" || "$q8" == "yes" ]]; then
  docker compose exec php symfony composer require security
  docker compose exec php symfony console make:user
  docker compose exec php symfony console make:security:form-login
fi

echo -e "Do you want install JWT bundle? (y/n): "
read q9

if [[ "$q9" == "y" || "$q9" == "yes" ]]; then
    docker compose exec php symfony composer require lexik/jwt-authentication-bundle
    docker compose exec php symfony console lexik:jwt:generate-keypair
fi

docker compose exec php symfony console about

echo -e "***********************************************"

echo "Access your app: http://localhost:$HOST_PORT"
echo
echo "****INSTALLATION COMPLETED****"
echo

echo -e "***********************************************"
