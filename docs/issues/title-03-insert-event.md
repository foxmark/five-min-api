# [Title] Slice 3: Insert event and audit logging

## What to build

Wire the Title entity into the existing Doctrine event infrastructure. The entity must implement `NotifiableInsertInterface` so that `EntityInsertEventListener` fires `Title.post.create` on `postPersist`. A `TitleEventSubscriber` listens to that event and logs the creation to the `doctrine_entity` log channel.

No update events — `NotifiableUpdatedInterface` is intentionally excluded.

## Acceptance criteria

- [ ] `Title` entity implements `NotifiableInsertInterface` (not `NotifiableUpdatedInterface`)
- [ ] `TitleChangeEvent` implements `PostChangeEventInterface` using `EntityEventTrait`
- [ ] `TitleChangeEvent::getPostCreateEventName()` returns `"Title.post.create"`
- [ ] `TitleEventSubscriber` subscribes only to `Title.post.create`
- [ ] Creating a Title via `POST /api/titles` results in a log entry in the `doctrine_entity` channel
- [ ] Updating a Title via `PUT`/`PATCH` does not produce an event log entry

## Blocked by

Slice 1 — [title-01-read-only-catalog.md](title-01-read-only-catalog.md)
