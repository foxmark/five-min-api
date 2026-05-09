# TASK-007: Full coverage verification

**Status:** DONE
**Plan ref:** 2026-05-09-increase-coverage.md § Final verification

## Steps

- [ ] Run: `docker compose exec php php bin/phpunit --coverage-text`

## Expected outcome

- All 15 original tests still pass
- 22 new tests added (Tasks 1-6)
- 37 total tests, all green
- Coverage for targeted classes at/near 100% (except documented Branch C lines)

| Class | Before | After |
|---|---|---|
| `GenericDtoProcessor` | ~95% | 100% |
| `MapManager` | ~90% | 100% |
| `MappedPaginator` | ~50% | 100% |
| `BookRepository` | ~67% | 100% |
| `EntityInsertEventListener` | 71% | ~86% |
| `EntityUpdatedEventListener` | 71% | ~86% |
