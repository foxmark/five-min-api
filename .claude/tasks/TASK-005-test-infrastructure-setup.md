# TASK-005: Test Infrastructure Setup
Status: done
Assignee: api-tester
Phase: red

---

## Description

Before tests can run, the test environment infrastructure must be verified and — if missing — put in place. This is a prerequisite for TASK-001 through TASK-004.

## Checklist

### 1. Verify API Platform test client is available

Check whether `ApiPlatform\Symfony\Bundle\Test\ApiTestCase` is available in vendor. API Platform 4.x ships it with `api-platform/symfony`. If missing, integration tests will use `Symfony\Bundle\FrameworkBundle\Test\WebTestCase` instead.

Command to check:
```
docker compose exec php php -r "class_exists('ApiPlatform\Symfony\Bundle\Test\ApiTestCase') ? print 'ok' : print 'missing';"
```

### 2. Verify test database config

The `when@test` doctrine config appends `_test` to the DB name. Confirm `DATABASE_URL` is set in `.env.test` or is inherited from the main `.env` as populated by Docker.

### 3. Create and migrate the test database

```
docker compose exec php symfony console doctrine:database:create --env=test --if-not-exists
docker compose exec php symfony console doctrine:migrations:migrate --env=test --no-interaction
```

### 4. Confirm phpunit runs

```
docker compose exec php php bin/phpunit --version
```

### 5. Document the test run command

Standard command for all subsequent test tasks:
```
docker compose exec php php bin/phpunit
```

For a specific suite:
```
docker compose exec php php bin/phpunit tests/Api/
docker compose exec php php bin/phpunit tests/Unit/
docker compose exec php php bin/phpunit tests/Integration/
```

## Acceptance criteria

- `docker compose exec php php bin/phpunit` exits with no fatal errors (only test failures from the Red phase tasks are expected)
- Test DB exists and has the `book` table
- `ApiTestCase` availability is documented as a note in the meeting record

## Notes

This task runs **in parallel** with TASK-001 through TASK-004 being written — the tester must confirm infra before the Red Gate meeting.

---

## Findings (recorded by api-tester)

### 1. ApiTestCase availability
`ApiPlatform\Symfony\Bundle\Test\ApiTestCase` is present at
`vendor/api-platform/symfony/Bundle/Test/ApiTestCase.php`.
It extends `KernelTestCase` and provides `createClient()`, `assertResponseIsSuccessful()`,
`assertJsonContains()`, and other API Platform-aware assertions.
**Decision:** TASK-001 (`BookTest`) extends `ApiTestCase`. TASK-004 extends `KernelTestCase`.
TASK-002 and TASK-003 extend plain `TestCase` (no kernel needed).

### 2. Test database configuration
`app/config/packages/doctrine.yaml` has a `when@test` block that appends `_test` (plus optional
`TEST_TOKEN` for parallel runs) to the DB name via `dbname_suffix`.
Main DB name is `five-min-api` (from root `.env`), so the test DB will be `five-min-api_test`.
`DATABASE_URL` is inherited from the root `.env` file — no separate entry needed in
`app/.env.test`.

### 3. Bootstrap
`app/tests/bootstrap.php` uses `Dotenv::bootEnv()` and reads `APP_ENV=test` from phpunit config
(`<server name="APP_ENV" value="test" force="true" />`).

### 4. PHPUnit version
PHPUnit 11.5.55 (confirmed via `php bin/phpunit --version`).

### 5. Test isolation strategy
`dama/doctrine-test-bundle` is **not** installed. Tests use manual transaction
`beginTransaction()` / `rollback()` in `setUp` / `tearDown` to keep tests isolated without
destroying data between runs.

### 6. Test run commands
```sh
# Full suite
docker compose exec php php bin/phpunit

# Per suite
docker compose exec php php bin/phpunit tests/Api/
docker compose exec php php bin/phpunit tests/Unit/
docker compose exec php php bin/phpunit tests/Integration/

# Red phase only
docker compose exec php php bin/phpunit --group red
```

### 7. Test database setup (run once)
```sh
docker compose exec php symfony console doctrine:database:create --env=test --if-not-exists
docker compose exec php symfony console doctrine:migrations:migrate --env=test --no-interaction
```
