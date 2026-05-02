# Meeting 001: Kickoff — Book API Test Plan
Date: 2026-05-02
Status: approved

---

## Context

The Book API resource is fully implemented. No tests exist. This meeting presents the planned test breakdown for approval before the api-tester begins writing the Red phase.

## What was reviewed

The team has read and analysed the following source files:

- `app/src/ApiResource/BookResource.php` — 6 operations (Get, GetCollection, Post, Put, Patch, Delete); 5 fields with validation constraints
- `app/src/Entity/Book.php` — 6 persisted fields; `initTimestamps` lifecycle callback; implements `NotifiableInsertInterface` + `NotifiableUpdatedInterface`
- `app/src/Mapper/BookMapper.php` — bidirectional mapping; `publicationYear` ↔ `publishedAt` conversion
- `app/src/Repository/BookRepository.php` — `findAvailable()` custom query; `DefaultOrderRepositoryInterface` (`id ASC`)
- `app/src/Event/BookChangeEvent.php` — `book.created` / `book.updated` event names
- `app/src/EventSubscriber/BookEventSubscriber.php` — logs info on create and update via named `doctrineEntityLogger`
- `app/src/State/Provider/GenericDtoProvider.php` — generic provider handling GetCollection (paginated) and Get (single)
- `app/src/State/Processor/GenericDtoProcessor.php` — generic processor handling Post, Put, Patch, Delete

## Proposed task breakdown

| Task | Title | Type | Assignee | Phase |
|------|-------|------|----------|-------|
| TASK-001 | Book API — Integration Tests (HTTP endpoints) | Integration | api-tester | Red |
| TASK-002 | BookMapper — Unit Tests | Unit | api-tester | Red |
| TASK-003 | BookEventSubscriber — Unit Tests | Unit | api-tester | Red |
| TASK-004 | BookRepository — Integration Tests | Integration | api-tester | Red |
| TASK-005 | Test Infrastructure Setup | Infrastructure | api-tester | Red |

TASK-005 is a prerequisite for all other tasks and runs first. TASK-001 through TASK-004 can be written in parallel once infra is confirmed.

---

## Agenda items

- [x] **Item 1 — Scope: agree on what is in and out of scope**

  In scope: API endpoint behaviour, mapper logic, subscriber logging, repository queries, validation constraints, pagination, basic error cases.

  Out of scope (not planned, can be added later): authentication/authorization tests (no auth is configured), performance/benchmarking (long-term goal documented in api-tester agent), Doctrine event listener tests (`EntityInsertEventListener` / `EntityUpdatedEventListener` — tested indirectly via integration tests).

  Decision needed: **Is this scope correct, or should anything be added/removed?**

- [x] **Item 2 — Test approach: confirm PHPUnit + ApiTestCase vs WebTestCase**

  `api-platform/symfony` v4 ships `ApiPlatform\Symfony\Bundle\Test\ApiTestCase`. TASK-005 will verify it is present. If missing, integration tests fall back to `WebTestCase` — this changes assertion style slightly but not coverage.

  Decision needed: **Acceptable to confirm the exact base class during TASK-005, before writing TASK-001?**

- [x] **Item 3 — Test database strategy**

  Doctrine is already configured with `dbname_suffix: '_test'` in `when@test`. The test DB needs to be created and migrated once before the Red Gate. The api-tester will handle this as part of TASK-005.

  Decision needed: **No action needed from you — confirming you are aware the test DB may not exist yet.**

- [x] **Item 4 — ISBN uniqueness / 409 vs 422 behavior**

  `Book.isbn` is `unique: true` at the Doctrine level. A duplicate POST will cause a DB constraint violation. API Platform may surface this as a 500, a 422, or a 409 depending on whether a UniqueEntity constraint is configured on the entity. Currently **no `#[UniqueEntity]` constraint is on the entity**.

  Decision needed: **Should we add `#[UniqueEntity(fields: ['isbn'])]` to `Book` before writing the duplicate-ISBN test? Or test the current behavior (likely a 500 on duplicate) and leave the constraint as a follow-up?**

  Default (async flag): proceed without `#[UniqueEntity]` for now; TASK-001 will include a test that documents the current behavior. Mark as a follow-up note in the task file.

- [x] **Item 5 — publicationYear field gap**

  `BookResource.publicationYear` maps to `Book.publishedAt` (a `DateTimeImmutable` stored as `datetime_immutable`). The mapper stores `{year}-01-01` on write and reads only the year component back. This means the day/month are silently discarded.

  Decision needed: **Is this mapping intentional and acceptable? Should the test assert the round-trip behavior (POST year 2001 → GET publicationYear 2001) without questioning the design?**

  Default (async flag): test the round-trip only. Raise a tech-lead flag as a note — this could be an ADR candidate.

---

## Sequence after approval

```
TASK-005 (infra)  →  TASK-001, TASK-002, TASK-003, TASK-004 (all Red)
                                        ↓
                         MEETING 002: RED GATE
          (user reviews failing tests before any implementation)
```

---

## Decisions

1. **Scope** — Approved as-is. No additions or removals.

2. **`#[UniqueEntity]` on `Book.isbn`** — Add `#[UniqueEntity(fields: ['isbn'])]` to `Book` before writing tests. The duplicate-ISBN test (`testIsbnUniqueConstraintReturns422`) must assert a proper 422. The backend-engineer adds the constraint as a prerequisite step before TASK-001 enters the Red phase.

3. **`ApiTestCase` vs `WebTestCase`** — `WebTestCase` fallback is acceptable. TASK-005 confirms which base class is available; TASK-001 uses whichever is found.

4. **`publicationYear` round-trip** — Test the round-trip as-is (POST year 2001 → GET publicationYear 2001). Do not change the design. Add a tech-lead note in the TASK-001 task file flagging this as an ADR candidate.
