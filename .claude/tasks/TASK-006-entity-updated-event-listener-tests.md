# TASK-006: EntityUpdatedEventListener uncovered branches

**Status:** DONE
**Plan ref:** 2026-05-09-increase-coverage.md § Task 6
**Target:** `app/src/EventListener/Doctrine/EntityUpdatedEventListener.php`
  - lines 37-39: `class_exists` false branch in `preUpdate`
  - lines 58-60: `class_exists` false branch in `postUpdate`
**New file:** `app/tests/Unit/EventListener/EntityUpdatedEventListenerTest.php`

## Strategy

Mirror Task 5. `FakeUpdatableEntity` resolves to `App\Event\FakeUpdatableEntityChangeEvent` which does not exist.
`PreUpdateEventArgs` must be mocked (constructor requires change-set data).

## Note

Branch C ("event exists but wrong interface") excluded — same constraint as Task 5.

## Steps

- [ ] Create `EntityUpdatedEventListenerTest.php` (dir already created by Task 5)
- [ ] Include 4 test methods + `FakeUpdatableEntity` stub
- [ ] Run: `docker compose exec php php bin/phpunit tests/Unit/EventListener/EntityUpdatedEventListenerTest.php`
- [ ] Commit: `test: cover class_exists false branches in EntityUpdatedEventListener`

## Done when

4 tests, all green. Lines 37-39 and 58-60 covered.
