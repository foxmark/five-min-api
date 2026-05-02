# TASK-003: BookEventSubscriber — Unit Tests
Status: done
Assignee: api-tester
Phase: done

---

## Description

Write PHPUnit unit tests for `BookEventSubscriber`. Uses a mock logger to verify log output without touching the real DI container.

Test file: `app/tests/Unit/EventSubscriber/BookEventSubscriberTest.php` — extends `PHPUnit\Framework\TestCase`.

## Test cases to write

### Subscriber registration

- `testSubscribesToBookCreatedEvent` — `getSubscribedEvents()` maps `BookChangeEvent::CREATED` to `onBookCreated`
- `testSubscribesToBookUpdatedEvent` — `getSubscribedEvents()` maps `BookChangeEvent::UPDATED` to `onBookUpdated`

### `onBookCreated`

- `testOnBookCreatedLogsInfoWithCorrectContext` — given a `BookChangeEvent` wrapping a Book with known id/isbn/title, assert that `$logger->info('Book created', [...])` is called with the correct context array

### `onBookUpdated`

- `testOnBookUpdatedLogsInfoWithCorrectContext` — same pattern for the updated handler

## Notes

- Mock `LoggerInterface` with `$this->createMock(LoggerInterface::class)` — no Symfony DI needed
- Book entity needs `id` set (reflection or constructor) to exercise the context array fully

## Acceptance criteria

- Tests are pure unit tests — no kernel, no DB
- Red on first run
- No trivial assertions

## Related files

- `app/src/EventSubscriber/BookEventSubscriber.php`
- `app/src/Event/BookChangeEvent.php`
- `app/src/Entity/Book.php`
