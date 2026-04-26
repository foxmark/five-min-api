# Entity Specification template: Book as a example

## 1. Domain Context

**What it represents:** A physical or digital book in a library catalogue.  
**Who uses it:** Librarians (manage catalogue), members (browse & check availability).  
**Domain:** Library management.

---

## 2. API Resource Fields

These are the fields exposed on the API DTO (`BookResource`).

| Field           | PHP type   | Nullable | Validation                          | Notes                          |
|-----------------|------------|----------|-------------------------------------|--------------------------------|
| id              | int        | yes      | none (read-only, set by DB)         |                                |
| title           | string     | yes      | NotBlank, Length(min:2, max:255)    |                                |
| isbn            | string     | yes      | NotBlank, Isbn                      |                                |
| authorName      | string     | yes      | NotBlank                            |                                |
| publicationYear | int        | yes      | Range(min:1000, max:2100)           | Exposed as year integer        |
| available       | bool       | no       | none                                | Defaults to true               |

---

## 3. Entity Fields

These are the fields stored in the database (`Book` entity). List fields that differ from the DTO here.

| Field       | PHP type           | Nullable | DB type              | Unique | Default | Notes                         |
|-------------|--------------------|----------|----------------------|--------|---------|-------------------------------|
| id          | int                | yes      | integer, auto-incr   | yes    | —       |                               |
| title       | string             | no       | varchar(255)         | no     | ''      |                               |
| isbn        | string             | no       | varchar(20)          | yes    | ''      | Unique constraint             |
| authorName  | string             | no       | varchar(255)         | no     | ''      |                               |
| publishedAt | DateTimeImmutable  | yes      | datetime_immutable   | no     | null    | Stores full date, not just year |
| available   | bool               | no       | boolean              | no     | true    |                               |
| createdAt   | DateTimeImmutable  | no       | datetime_immutable   | no     | —       | Set automatically on PrePersist; never exposed on API |

---

## 4. Field Mappings (DTO ↔ Entity differences)

Explicit transformations the mapper must perform.

| DTO field       | Entity field  | Direction     | Transformation                                                                 |
|-----------------|---------------|---------------|--------------------------------------------------------------------------------|
| publicationYear | publishedAt   | both          | DTO int year → entity `{year}-01-01` DateTimeImmutable; entity → extract `Y` as int |

---

## 5. API Operations

| Operation     | Enabled | Notes                         |
|---------------|---------|-------------------------------|
| GetCollection | yes     | paginated                     |
| Get           | yes     |                               |
| Post          | yes     |                               |
| Put           | yes     |                               |
| Patch         | yes     |                               |
| Delete        | yes     |                               |

**Pagination:** enabled, default 10 per page, client-configurable, max 30.

---

## 6. Default Collection Ordering

Implement `DefaultOrderRepositoryInterface` on the repository.

| Field | Direction |
|-------|-----------|
| id    | ASC       |

---

## 7. Events

The entity implements both `NotifiableInsertInterface` and `NotifiableUpdatedInterface`.

**Event class:** `BookChangeEvent`  
**Event constants:** `book.created`, `book.updated`

**Subscriber logs these fields on both create and update:**
- `entity_class`
- `entity_id`
- `isbn`
- `title`

---

## 8. Custom Repository Methods

| Method          | Returns     | Description                                 |
|-----------------|-------------|---------------------------------------------|
| findAvailable() | `Book[]`    | All books where `available = true`, ordered by `title ASC` |

---

## 9. Business Rules

- `isbn` must be unique across all books.
- `createdAt` is set once on first persist and never updated.
- `available` defaults to `true` on creation if not specified.
- `publicationYear` is optional; if absent, `publishedAt` is stored as `null`.
- A book cannot be created without `title`, `isbn`, and `authorName`.

---

## 10. User Stories

**As a librarian:**
- I want to add a new book (POST) with title, ISBN, author, and publication year so it appears in the catalogue.
- I want to update a book's availability (PATCH) so members know if it can be borrowed.
- I want to replace all book details at once (PUT) when correcting a mis-catalogued entry.
- I want to delete a book (DELETE) when it is permanently removed from the collection.

**As a member:**
- I want to list all books (GET collection, paginated) so I can browse the catalogue.
- I want to fetch a single book by ID (GET) to see its full details.

---

## 11. Test Scenarios

### Happy path
- POST with all valid fields → 201, returns new book with id
- GET collection → 200, paginated list, ordered by id ASC
- GET single → 200, correct fields
- PUT with updated title → 200, title changed
- PATCH `available: false` → 200, available is false
- DELETE → 204, subsequent GET returns 404

### Validation / edge cases
- POST missing `title` → 422 Unprocessable Entity
- POST invalid ISBN format → 422
- POST `publicationYear` below 1000 → 422
- POST duplicate `isbn` → 422 (or 409 depending on implementation)
- GET non-existent id → 404
- PATCH read-only `id` field → ignored, not updated

### Events
- POST a book → `book.created` event fired, log entry written with isbn and title
- PUT/PATCH a book → `book.updated` event fired, log entry written with isbn and title
