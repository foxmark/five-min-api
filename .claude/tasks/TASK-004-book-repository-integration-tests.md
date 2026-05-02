# TASK-004: BookRepository — Integration Tests
Status: done
Assignee: api-tester
Phase: done

---

## Description

Write PHPUnit integration tests for `BookRepository` using a real database (test env). These verify custom query methods and the `DefaultOrderRepositoryInterface` contract.

Test file: `app/tests/Integration/Repository/BookRepositoryTest.php` — extends `KernelTestCase`.

## Test cases to write

### `findAvailable(): Book[]`

- `testFindAvailableReturnsOnlyAvailableBooks` — seed 2 available + 1 unavailable, assert result contains exactly the 2 available
- `testFindAvailableReturnsEmptyArrayWhenNoBooksAvailable`
- `testFindAvailableOrdersByTitleAscending` — seed books out of alphabetical order, assert returned order

### `getDefaultOrder()`

- `testGetDefaultOrderReturnsIdAsc` — assert `['id' => 'ASC']`

## Infrastructure notes

- Use Symfony's `KernelTestCase` with `EntityManagerInterface` from the container for seeding
- Wrap each test in a transaction and roll back — or truncate after each test
- Test DB must exist with the book schema applied

## Acceptance criteria

- Tests use the real test database, not mocks
- Red on first run (repository may work fine — these may go green immediately, which is also valid for existing code; the point is to lock in the contract)
- Tests are independent of each other

## Related files

- `app/src/Repository/BookRepository.php`
- `app/src/Repository/DefaultOrderRepositoryInterface.php`
- `app/src/Entity/Book.php`
