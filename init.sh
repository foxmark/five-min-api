#!/bin/bash

if [[ ! -d "app" ]]; then
  mkdir app
fi

source .env
docker compose up -d

echo -e "-> docker compose exec php symfony new . --no-git --version=\"lts\""
read s1
docker compose exec php symfony new . --no-git --version="lts"

echo -e "-> compose exec php symfony composer require --dev symfony/maker-bundle"
read s3
docker compose exec php symfony composer require --dev symfony/maker-bundle

echo -e "-> docker compose exec php symfony composer require --dev symfony/profiler-pack symfony/debug-bundle symfony/test-pack"
read q3

docker compose exec php symfony composer require --dev symfony/profiler-pack symfony/debug-bundle symfony/test-pack

echo -e "-> compose exec php symfony composer require symfony/orm-pack --no-interaction --no-scripts"
read q4

docker compose exec php symfony composer require symfony/orm-pack --no-interaction --no-scripts

echo -e "-> compose exec php symfony composer require --dev doctrine/doctrine-fixtures-bundle"
read q5
docker compose exec php symfony composer require --dev doctrine/doctrine-fixtures-bundle

echo -e "Do you want create new database for the project? (y/n): "
read q5

if [[ "$q5" == "y" || "$q5" == "yes" ]]; then
    docker compose exec php symfony console doctrine:database:create
    echo -e ' '
fi

echo -e "-> docker compose exec php symfony composer require api"
read q6

docker compose exec php symfony composer require api

echo -e "Do you want install JWT bundle? (y/n): "
read q7

if [[ "$q7" == "y" || "$q7" == "yes" ]]; then
    docker compose exec php symfony composer require lexik/jwt-authentication-bundle
    docker compose exec php symfony console lexik:jwt:generate-keypair
fi

docker -e compose exec php symfony console about

echo -e "***********************************************"

echo "Access your app: http://localhost:$HOST_PORT"
echo
echo "****INSTALLATION COMPLETED****"
echo

echo -e "***********************************************"
