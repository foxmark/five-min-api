# TASK-005: EntityInsertEventListener uncovered branches

**Status:** DONE
**Plan ref:** 2026-05-09-increase-coverage.md § Task 5
**Target:** `app/src/EventListener/Doctrine/EntityInsertEventListener.php`
  - lines 36-38: `class_exists` false branch in `prePersist`
  - lines 56-58: `class_exists` false branch in `postPersist`
**New file:** `app/tests/Unit/EventListener/EntityInsertEventListenerTest.php`

## Strategy

`FakeInsertableEntity` (defined in test file) resolves to `App\Event\FakeInsertableEntityChangeEvent` which does not exist → `class_exists` guard returns false → no dispatch.

## Note

Branch C ("event exists but wrong interface") is excluded — requires production-namespace class creation.

## Steps

- [ ] Create `app/tests/Unit/EventListener/` directory
- [ ] Create `EntityInsertEventListenerTest.php` with 4 test methods + `FakeInsertableEntity` stub
- [ ] Run: `docker compose exec php php bin/phpunit tests/Unit/EventListener/EntityInsertEventListenerTest.php`
- [ ] Commit: `test: cover class_exists false branches in EntityInsertEventListener`

## Done when

4 tests, all green. Lines 36-38 and 56-58 covered.
