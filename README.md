# 5 min API app

## Installation

```sh
docker compose up -d
```

```sh
docker compose exec php symfony new . --no-git --version="lts"
```

```sh
docker compose exec php symfony composer require symfony/monolog-bundle
```

```sh
docker compose exec php symfony composer require --dev symfony/maker-bundle
```

```sh
docker compose exec php symfony composer require --dev symfony/profiler-pack symfony/debug-bundle symfony/test-pack
```

```sh
docker compose exec php symfony composer require symfony/orm-pack --no-interaction --no-scripts
```

```sh
docker compose exec php symfony composer require --dev doctrine/doctrine-fixtures-bundle
```

```sh
docker compose exec php symfony console doctrine:database:create
```

```sh
docker compose exec php symfony composer require api
```


## Validate installation

```sh
docker compose exec php symfony console about
```

## Define entities

```sh
docker compose exec php symfony console make:entity
```

#### Folder

 - name
 - description
 - createdAt
 - updatedAt
 - path
 - parent

#### File

 - name
 - description
 - size
 - mimeType
 - createdAt
 - updatedAt
 - path
 - folder

### Generate migration from entities

```sh
docker compose exec php symfony console make:migration
```

### Run migrations

```sh
docker compose exec php symfony console doctrine:migrations:migrate
```

### cache clear

```sh
docker compose exec php symfony console cache:clear
```

### Misc.

```sh
docker compose exec php symfony console debug:router
```

```sh
docker compose exec php symfony console debug:config
```

```sh
docker compose exec php symfony console config:dump
```

```sh
docker compose exec php symfony console debug:autowiring
```