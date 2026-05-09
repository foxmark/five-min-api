# [Title] Slice 1: Read-only Title catalog

## What to build

Add a read-only `Title` API resource for movie titles, cutting through all layers end-to-end: Doctrine entity, database migration, mapper, repository with default alphabetical ordering, and API Platform operations (`GetCollection`, `Get` only — no `DELETE`). A `405` response must be returned for `DELETE /api/titles/{id}`.

## Acceptance criteria

- [ ] `GET /api/titles` returns 200 with `application/ld+json`
- [ ] `GET /api/titles/{id}` returns 200 for an existing Title
- [ ] `GET /api/titles/99999` returns 404
- [ ] `DELETE /api/titles/{id}` returns 405
- [ ] Collection defaults to 10 items per page, client-configurable up to 30
- [ ] Collection is ordered `title ASC` by default
- [ ] `TitleRepositoryTest` verifies alphabetical default ordering
- [ ] `TitleApiTest` covers GET collection, GET single, 404, and 405 on DELETE

## Blocked by

None — can start immediately.
