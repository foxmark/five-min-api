# TASK-002: MapManager throws RuntimeException for unmapped class

**Status:** DONE
**Plan ref:** 2026-05-09-increase-coverage.md § Task 2
**Target:** `app/src/Mapper/MapManager.php` line 25 — `throw new \RuntimeException(...)`
**New file:** `app/tests/Unit/Mapper/MapManagerTest.php`

## Why

No existing test calls `getMapper()` with an unknown class — the exception branch is never hit.

## Steps

- [ ] Create `app/tests/Unit/Mapper/` directory
- [ ] Create `MapManagerTest.php` with `testGetMapperThrowsRuntimeExceptionForUnmappedClass()`
- [ ] Run: `docker compose exec php php bin/phpunit tests/Unit/Mapper/MapManagerTest.php`
- [ ] Commit: `test: cover RuntimeException branch in MapManager::getMapper()`

## Done when

1 test, 1 assertion, green. `MapManager` line 25 is covered.
