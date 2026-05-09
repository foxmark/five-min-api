# [Title] Slice 2: Write operations

## What to build

Add `Post`, `Put`, and `Patch` operations to the `Title` resource with full validation. All required fields must be validated; `durationMinutes` is optional. PUT and PATCH on a non-existent Title must return 404.

## Acceptance criteria

- [ ] `POST /api/titles` with valid payload returns 201
- [ ] `POST /api/titles` without `title` returns 422
- [ ] `POST /api/titles` without `director` returns 422
- [ ] `POST /api/titles` without `releaseYear` returns 422
- [ ] `POST /api/titles` with `releaseYear` < 1888 returns 422
- [ ] `POST /api/titles` with `releaseYear` > 2100 returns 422
- [ ] `POST /api/titles` with `durationMinutes` < 1 returns 422
- [ ] `POST /api/titles` with `durationMinutes` > 600 returns 422
- [ ] `POST /api/titles` without `durationMinutes` returns 201 (field is optional)
- [ ] `PUT /api/titles/{id}` with valid payload returns 200
- [ ] `PUT /api/titles/99999` returns 404
- [ ] `PATCH /api/titles/{id}` with partial payload returns 200
- [ ] `PATCH /api/titles/99999` returns 404
- [ ] `TitleApiTest` covers all of the above cases

## Blocked by

Slice 1 — [title-01-read-only-catalog.md](title-01-read-only-catalog.md)
