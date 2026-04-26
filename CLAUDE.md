# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

A Docker wrapper (nginx + PHP-FPM + MySQL 8) around a Symfony application. The application code lives in `app/` and is mounted into the containers. **PHP is not installed on the host OS** — every PHP, Symfony, and Composer command must run inside the `php` container.

## Running commands

All commands follow the same pattern:

```sh
docker compose exec php <command>
```

```sh
# Verify PHP version
docker compose exec php php -v

# Symfony console
docker compose exec php symfony console <command>

# Composer
docker compose exec php symfony composer <command>
```

## Container management

```sh
docker compose up -d       # start all containers
docker compose down        # stop and remove containers
docker compose ps          # check running containers
docker compose logs php    # tail php-fpm logs
```

## Configuration

All environment variables are in `.env` at the repo root. Key variables:

| Variable | Purpose |
|----------|---------|
| `APP_NAME` | Prefix for container names (`{APP_NAME}-php`, `{APP_NAME}-nginx`, `{APP_NAME}-mysql8`) |
| `HOST_PORT` | Local port for the app (default `8015`) |
| `MYSQL_PORT` | Local port for MySQL (default `3315`) |
| `PHP_IMAGE_VERSION` | Tag for the `foxmark/php8.2.12-fpm` image currently `3.0` or `4.0` (added support for rmq) |
| `MYSQL_IMAGE_VERSION` | MySQL image tag, build and tested with `8.4.3`  |
| `UID` / `GID` | Run containers as the host user to avoid file permission issues |

## Stack layout

```
docker-compose.yml      # service definitions
.env                    # environment config (copy .env.example if starting fresh)
docker/
  nginx/default.conf    # nginx vhost config
  php/config/           # php.ini overrides and xdebug config
app/                    # Symfony application (mounted into php and nginx containers)
data/mysql/             # MySQL data volume (persisted locally, not committed)
```

## Fresh installation

```sh
./install.sh   # interactive step-by-step setup
```

## Common problems

- when running `docker compose up` first instead of starting with `./install.sh` `app` directory might get `root` (or other user) ownership and it will be locked for editing, to fix it change folder owner using `chown -R <user>:<group> app/` command.