# TASK-003: MappedPaginator unit tests

**Status:** DONE
**Plan ref:** 2026-05-09-increase-coverage.md § Task 3
**Target:** `app/src/State/Pagination/MappedPaginator.php` — all uncovered lines
**New file:** `app/tests/Unit/State/MappedPaginatorTest.php`

## Uncovered lines

- `getCurrentPage()` (0%)
- `getItemsPerPage()` (0%)
- `getLastPage()` zero-items and zero-perpage branches (66%)
- `getIterator()` foreach body (50%)
- `count()` (0%)

## Steps

- [ ] Create `app/tests/Unit/State/` directory
- [ ] Create `MappedPaginatorTest.php` with 8 test methods covering all branches
- [ ] Run: `docker compose exec php php bin/phpunit tests/Unit/State/MappedPaginatorTest.php`
- [ ] Commit: `test: cover all uncovered MappedPaginator methods including zero-item and zero-perpage branches`

## Done when

8 tests, all green. All previously uncovered `MappedPaginator` lines are covered.
