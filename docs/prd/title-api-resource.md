# PRD: Title API Resource

## Problem Statement

The catalog currently only supports Book resources (physical library items). There is no way to manage movie Titles through the API. Consumers need to create, retrieve, and update movie Titles using the same REST conventions already established for Books.

## Solution

Introduce a `Title` API resource representing a movie title in the catalog. It follows the same provider/processor/mapper architecture used by `Book`, exposed under `/api/titles` with full JSON-LD support.

## User Stories

1. As an API consumer, I want to POST a new Title with a title, director, releaseYear, and optional durationMinutes, so that I can add movies to the catalog.
2. As an API consumer, I want a 201 response with the created Title when I POST successfully, so that I can confirm the resource was created and obtain its ID.
3. As an API consumer, I want a 422 response when I omit the title field on POST, so that I receive clear validation feedback.
4. As an API consumer, I want a 422 response when I omit the director field on POST, so that I receive clear validation feedback.
5. As an API consumer, I want a 422 response when I omit the releaseYear field on POST, so that I receive clear validation feedback.
6. As an API consumer, I want a 422 response when I submit a releaseYear before 1888, so that only historically valid years are accepted.
7. As an API consumer, I want a 422 response when I submit a releaseYear after 2100, so that obviously erroneous years are rejected.
8. As an API consumer, I want a 422 response when I submit a durationMinutes below 1, so that invalid runtimes are rejected.
9. As an API consumer, I want a 422 response when I submit a durationMinutes above 600, so that unreasonably large runtimes are rejected.
10. As an API consumer, I want to omit durationMinutes when creating or updating a Title, so that I can catalog titles with unknown runtimes.
11. As an API consumer, I want to GET a single Title by ID, so that I can display its details.
12. As an API consumer, I want a 404 response when I GET a Title that does not exist, so that I can handle missing resources gracefully.
13. As an API consumer, I want to GET a paginated collection of Titles, so that I can browse the catalog without loading everything at once.
14. As an API consumer, I want the collection to default to 10 Titles per page, so that responses stay fast.
15. As an API consumer, I want to request up to 30 Titles per page via a query parameter, so that I can load larger sets when needed.
16. As an API consumer, I want the default collection order to be `title ASC`, so that Titles are returned alphabetically without specifying a sort.
17. As an API consumer, I want to PUT a Title to replace all its fields, so that I can fully update a record.
18. As an API consumer, I want a 404 response when I PUT a Title that does not exist, so that I know the resource was not found.
19. As an API consumer, I want to PATCH a Title to update individual fields, so that I can make partial updates efficiently.
20. As an API consumer, I want a 404 response when I PATCH a Title that does not exist, so that I know the resource was not found.
21. As an API consumer, I want DELETE to be unavailable on Titles, so that the catalog remains immutable once populated.
22. As a system operator, I want a `Title.post.create` event fired whenever a Title is persisted, so that downstream systems can react to new movie titles.
23. As a system operator, I want the creation event logged to the `doctrine_entity` log channel, so that I have an audit trail of all Title insertions.

## Implementation Decisions

### Modules

- **TitleResource (API DTO)** — API Platform resource class configured with `GetCollection`, `Get`, `Post`, `Put`, `Patch` operations only (no `Delete`). Uses `GenericDtoProvider` and `GenericDtoProcessor`. Pagination settings match Book: 10 per page default, client-configurable up to 30.

- **Title (Doctrine entity)** — Persisted entity with `title`, `director`, `releaseYear`, `durationMinutes` (nullable int), and `createdAt` (set via `PrePersist`). Implements `NotifiableInsertInterface` only — no `NotifiableUpdatedInterface`.

- **TitleMapper** — Implements `EntityMapperInterface`. Provides `getSupportedResourceClass()`, `toResource(entity)`, and `toEntity(dto, ?entity)`. Handles nullable `durationMinutes` in both directions.

- **TitleRepository** — Extends `ServiceEntityRepository<Title>`. Implements `DefaultOrderRepositoryInterface` returning `['title' => 'ASC']`, which `GenericDtoProvider` applies automatically to every collection query.

- **TitleChangeEvent** — Event class implementing `PostChangeEventInterface` (and `PreChangeEventInterface` via `EntityEventTrait`). Resolves event names from entity class name via convention: `Title.post.create`, `Title.pre.create`.

- **TitleEventSubscriber** — Listens to `Title.post.create` only. Logs the creation (title ID and title name) to the `doctrineEntityLogger` channel. Does not subscribe to update events.

- **Database migration** — Adds the `title` table with all required columns.

### API Contract

- Base path: `/api/titles`
- Content-Type: `application/ld+json` (GET/POST/PUT), `application/merge-patch+json` (PATCH)
- Fields exposed: `id`, `title`, `director`, `releaseYear`, `durationMinutes`

### Validation Rules

| Field | Constraints |
|---|---|
| `title` | NotBlank, Length(min:1, max:255) |
| `director` | NotBlank, Length(min:2, max:255) |
| `releaseYear` | NotBlank, Range(min:1888, max:2100) |
| `durationMinutes` | Range(min:1, max:600), nullable |

## Testing Decisions

### What makes a good test

Tests assert on external HTTP behavior (status codes, response structure) or on observable repository output — not on internal implementation details like which mapper method was called or how many SQL queries ran.

### Tests to write

**`TitleApiTest` (functional, extends `ApiTestCase`)** — mirrors `BookApiTest` in structure:
- Endpoint definition: GET collection returns 200, GET single returns 200, GET non-existent returns 404
- Write operations: POST returns 201, PUT returns 200, PATCH returns 200
- No DELETE: DELETE returns 405
- 404 on PUT/PATCH for non-existent Title
- Validation: 422 for missing `title`, missing `director`, missing `releaseYear`, `releaseYear` below 1888, `releaseYear` above 2100, `durationMinutes` below 1, `durationMinutes` above 600
- Optional field: POST without `durationMinutes` returns 201

**`TitleRepositoryTest` (integration, extends `KernelTestCase`)** — mirrors `BookRepositoryTest` in structure:
- `getDefaultOrder()` returns `['title' => 'ASC']`
- Collection query returns Titles in alphabetical order

Prior art: `tests/Api/BookApiTest.php`, `tests/Integration/Repository/BookRepositoryTest.php`.

## Out of Scope

- Relating Titles to Books (no foreign-key or association between the two resources)
- Update events (`NotifiableUpdatedInterface`) — Title only fires on insert
- Search or filter endpoints beyond the default paginated collection
- Authentication or authorization on Title endpoints

## Further Notes

- 1888 as the minimum `releaseYear` corresponds to the earliest known motion picture (Roundhay Garden Scene). This is an intentional domain constraint, not an arbitrary floor.
- `durationMinutes` is nullable at the DB level. The DTO exposes it as `?int`. No default value is set.
- `TitleEventSubscriber` subscribes to `Title.post.create` using the event name resolved by `TitleChangeEvent::getPostCreateEventName()` via `EntityEventTrait`.
