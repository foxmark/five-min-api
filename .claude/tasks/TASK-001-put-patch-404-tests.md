# TASK-001: PUT/PATCH non-existent resource → 404

**Status:** DONE
**Plan ref:** 2026-05-09-increase-coverage.md § Task 1
**Target:** `app/src/State/Processor/GenericDtoProcessor.php` line 40 — `throw new ItemNotFoundException()`
**File to edit:** `app/tests/Api/BookApiTest.php`

## Why

The exception branch is never exercised — happy-path tests always use a real book ID.

## Steps

- [ ] Append `testPutNonExistentBookReturns404()` and `testPatchNonExistentBookReturns404()` to `BookApiTest`
- [ ] Run: `docker compose exec php php bin/phpunit tests/Api/BookApiTest.php`
- [ ] Commit: `test: cover ItemNotFoundException branch in GenericDtoProcessor (PUT/PATCH 404)`

## Done when

Both new tests pass; `GenericDtoProcessor` line 40 is covered.
