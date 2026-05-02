# TASK-001: Book API — Integration Tests (HTTP endpoints)
Status: done
Assignee: api-tester
Phase: done

---

## Description

Write PHPUnit integration tests covering all six HTTP operations exposed by `BookResource` via `GenericDtoProvider` and `GenericDtoProcessor`. Tests live in `app/tests/Api/BookTest.php` and extend API Platform's `ApiTestCase`.

The tests must **fail for the right reason** before any implementation changes are made (Red phase). They define what "done" means for the Book API.

## Endpoints under test

| Method | Path | Operation |
|--------|------|-----------|
| GET    | /api/books | GetCollection |
| GET    | /api/books/{id} | Get |
| POST   | /api/books | Post |
| PUT    | /api/books/{id} | Put |
| PATCH  | /api/books/{id} | Patch |
| DELETE | /api/books/{id} | Delete |

## Test cases to write

### Happy path

- `testGetBookCollectionReturnsEmptyList` — GET /api/books with no data returns 200 with empty `hydra:member`
- `testGetBookCollectionReturnsPaginatedList` — GET /api/books with seeded data returns correct page structure and `hydra:totalItems`
- `testGetBookCollectionDefaultsTo10ItemsPerPage` — verify default pagination limit
- `testGetBookCollectionClientCanRequestDifferentPageSize` — `itemsPerPage` query param honored (max 30)
- `testGetSingleBookReturnsCorrectShape` — GET /api/books/{id} returns all fields: id, title, isbn, authorName, publicationYear, available
- `testCreateBookReturns201WithLocation` — POST creates book and returns 201 with Location header
- `testCreateBookPersistsData` — POST then GET verifies round-trip
- `testReplaceBookWithPutReturns200` — PUT replaces all fields
- `testPartialUpdateBookWithPatchReturns200` — PATCH updates only provided fields
- `testDeleteBookReturns204` — DELETE returns 204
- `testDeletedBookReturns404` — DELETE then GET returns 404

### Validation failures (expect 422)

- `testCreateBookWithBlankTitleReturns422`
- `testCreateBookWithTitleTooShortReturns422` — min 2 chars
- `testCreateBookWithTitleTooLongReturns422` — max 255 chars
- `testCreateBookWithBlankIsbnReturns422`
- `testCreateBookWithInvalidIsbnReturns422` — non-ISBN string
- `testCreateBookWithBlankAuthorNameReturns422`
- `testCreateBookWithPublicationYearBelowRangeReturns422` — year < 1000
- `testCreateBookWithPublicationYearAboveRangeReturns422` — year > 2100

### Not-found cases (expect 404)

- `testGetNonExistentBookReturns404`
- `testPutNonExistentBookReturns404`
- `testPatchNonExistentBookReturns404`
- `testDeleteNonExistentBookReturns204` — Delete of missing resource: verify behavior (API Platform returns 404 by default when provider returns null; processor may differ — confirm during Red phase)

### Field mapping / edge cases

- `testPublicationYearNullWhenNotProvided` — optional field defaults to null
- `testAvailableDefaultsToTrue` — `available` field defaults to true on create
- `testIsbnUniqueConstraintReturns422` — duplicate ISBN returns 422; this requires `#[UniqueEntity(fields: ['isbn'])]` on `Book` (see Prerequisite note below)

## Prerequisite complete: #[UniqueEntity(fields: ['isbn'])] added to Book entity

## Prerequisite note (from MEETING-001 decision)

`#[UniqueEntity(fields: ['isbn'])]` must be added to `app/src/Entity/Book.php` before this task enters the Red phase. Without it, a duplicate POST causes a DB constraint violation surfaced as a 500, and `testIsbnUniqueConstraintReturns422` cannot assert a 422. The backend-engineer handles this addition; the api-tester confirms it is present before writing the duplicate-ISBN test.

## Tech-lead note (from MEETING-001 decision)

`publicationYear` round-trip behavior: `BookMapper` stores `{year}-01-01` on write and reads only the year component back. The day and month are silently discarded. Tests assert the round-trip as-is (POST year 2001 → GET publicationYear 2001) without changing the design. This mapping decision is an ADR candidate — the tech-lead should evaluate whether lossy date truncation is intentional and document it formally.

## Infrastructure notes

- Database: `_test` suffix database (configured in `doctrine.yaml` `when@test`)
- No API Platform `ApiTestCase` is in dev deps yet — check if `api-platform/core` ships it; may need `WebTestCase` from `symfony/browser-kit` instead
- Test data: use inline factory methods inside the test class (no Fixtures bundle needed for unit-style setup); OR use `doctrine/doctrine-fixtures-bundle` (already in dev deps)
- Each test must reset DB state — use transactions or `--env=test` with recreate; coordinate with backend-engineer if schema is not yet migrated for test DB

## Acceptance criteria

- All test methods exist in `app/tests/Api/BookTest.php`
- Running `docker compose exec php php bin/phpunit` produces failures (not errors) for all non-trivially-covered cases
- Every test has a clear Arrange / Act / Assert structure
- No test passes trivially

## Related files

- `app/src/ApiResource/BookResource.php`
- `app/src/Entity/Book.php`
- `app/src/State/Provider/GenericDtoProvider.php`
- `app/src/State/Processor/GenericDtoProcessor.php`
- `app/src/Mapper/BookMapper.php`
