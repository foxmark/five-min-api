# TASK-002: BookMapper — Unit Tests
Status: done
Assignee: api-tester
Phase: done

---

## Description

Write PHPUnit pure unit tests for `BookMapper`. These run in isolation (no Symfony kernel, no database) and verify the two-way mapping contract between `Book` (entity) and `BookResource` (DTO).

Test file: `app/tests/Unit/Mapper/BookMapperTest.php` — extends `PHPUnit\Framework\TestCase`.

## Test cases to write

### `toResource(Book): BookResource`

- `testToResourceMapsIdCorrectly`
- `testToResourceMapsTitleCorrectly`
- `testToResourceMapsIsbnCorrectly`
- `testToResourceMapsAuthorNameCorrectly`
- `testToResourceMapsAvailableCorrectly`
- `testToResourceMapsPublicationYearFromPublishedAt` — `publishedAt = 2001-06-15` → `publicationYear = 2001`
- `testToResourcePublicationYearIsNullWhenPublishedAtIsNull` — `publishedAt = null` → `publicationYear = null`

### `toEntity(BookResource, ?Book): Book`

- `testToEntityCreatesNewBookWhenNoExistingEntityGiven` — second arg null → new `Book` instance
- `testToEntitySetsTitle`
- `testToEntitySetsIsbn`
- `testToEntitySetsAuthorName`
- `testToEntitySetsAvailable`
- `testToEntitySetsPublishedAtFromPublicationYear` — `publicationYear = 2001` → `publishedAt = DateTimeImmutable('2001-01-01')`
- `testToEntityPublishedAtIsNullWhenPublicationYearIsNull`
- `testToEntityUpdatesExistingBookWhenEntityIsProvided` — second arg is an existing Book, assert it is mutated in place (same object reference)

### Contract checks

- `testGetSupportedResourceClassReturnsBookResource`
- `testGetSupportedEntityClassReturnsBook`

## Acceptance criteria

- All tests are pure unit tests (no kernel boot, no DB, no HTTP)
- Running `docker compose exec php php bin/phpunit tests/Unit` returns failures on first run (Red)
- No test passes trivially

## Related files

- `app/src/Mapper/BookMapper.php`
- `app/src/ApiResource/BookResource.php`
- `app/src/Entity/Book.php`
