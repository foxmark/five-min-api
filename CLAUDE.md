# CLAUDE.md

Docker wrapper (nginx + PHP-FPM + MySQL 8) around a Symfony app in `app/`. PHP not on host — all commands via `docker compose exec php`.

## Commands

```sh
docker compose exec php php -v
docker compose exec php symfony console <cmd>
docker compose exec php symfony composer <cmd>
docker compose up -d / down / ps / logs php
```

## Config (`.env`)

| Var | Notes |
|-----|-------|
| `APP_NAME` | container name prefix (`{APP_NAME}-php/nginx/mysql8`) |
| `HOST_PORT` | default `8015` |
| `MYSQL_PORT` | default `3315` |
| `PHP_IMAGE_VERSION` | `3.0` or `4.0` (4.0 adds RMQ) |
| `MYSQL_IMAGE_VERSION` | tested with `8.4.3` |
| `UID` / `GID` | run as host user |

## Layout

```
docker-compose.yml / .env / docker/{nginx,php}/ / app/ / data/mysql/
```

## Setup & Gotchas

- Fresh install: `./install.sh`
- If `app/` ends up owned by root after `docker compose up`, fix with `chown -R <user>:<group> app/`
