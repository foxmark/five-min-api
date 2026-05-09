# TASK-004: BookRepository::findAvailable() integration test

**Status:** DONE
**Plan ref:** 2026-05-09-increase-coverage.md § Task 4
**Target:** `app/src/Repository/BookRepository.php` — entire `findAvailable()` method (6 uncovered lines)
**New file:** `app/tests/Integration/Repository/BookRepositoryTest.php`

## Why

`findAvailable()` is a query-builder method — must be tested against a real database.

## Steps

- [ ] Create `app/tests/Integration/Repository/` directory
- [ ] Create `BookRepositoryTest.php` with 3 test methods (filters, ordering, empty result)
- [ ] Run: `docker compose exec php php bin/phpunit tests/Integration/Repository/BookRepositoryTest.php`
- [ ] Commit: `test: cover BookRepository::findAvailable() with integration tests`

## Done when

3 tests, all green. All 6 uncovered lines in `findAvailable()` are covered.
