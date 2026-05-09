# Increase PHPUnit Code Coverage Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add targeted tests to cover all identified uncovered lines in `GenericDtoProcessor`, `MapManager`, `MappedPaginator`, `BookRepository`, `EntityInsertEventListener`, and `EntityUpdatedEventListener`.

**Architecture:** Tests are split by kind — API integration tests extend the existing `BookApiTest` pattern using `ApiTestCase`; unit tests use plain `PHPUnit\Framework\TestCase` with mocks; one integration test uses `KernelTestCase` to reach Doctrine directly. No production code changes are required; all uncovered paths are reachable via missing test scenarios.

**Tech Stack:** Symfony 7.4, API Platform 4.x, Doctrine ORM, PHPUnit, Docker (all commands via `docker compose exec php`)

---

## Task 1: API test — PUT/PATCH non-existent resource → 404

**Target:** `app/src/State/Processor/GenericDtoProcessor.php` line 40 — `throw new ItemNotFoundException()`.

**Why it is uncovered:** The existing happy-path PUT/PATCH tests always use a real book ID. The exception branch is never exercised.

**File to edit:** `app/tests/Api/BookApiTest.php`

### Steps

- [ ] Open `app/tests/Api/BookApiTest.php` and append two test methods inside the `BookApiTest` class, before the closing brace:

```php
    public function testPutNonExistentBookReturns404(): void
    {
        $this->client->request('PUT', '/api/books/99999', [
            'headers' => ['Content-Type' => 'application/ld+json'],
            'json' => [
                'title' => 'Ghost Title',
                'isbn' => '9780743273565',
                'authorName' => 'Ghost Author',
                'publicationYear' => 2000,
                'available' => true,
            ],
        ]);

        $this->assertResponseStatusCodeSame(404);
    }

    public function testPatchNonExistentBookReturns404(): void
    {
        $this->client->request('PATCH', '/api/books/99999', [
            'headers' => ['Content-Type' => 'application/merge-patch+json'],
            'json' => ['title' => 'Ghost Patch'],
        ]);

        $this->assertResponseStatusCodeSame(404);
    }
```

- [ ] Run the tests:

```sh
docker compose exec php php bin/phpunit tests/Api/BookApiTest.php
```

Expected: both new tests pass (green). `GenericDtoProcessor` line 40 is now covered.

- [ ] Commit:

```sh
git add app/tests/Api/BookApiTest.php
git commit -m "test: cover ItemNotFoundException branch in GenericDtoProcessor (PUT/PATCH 404)"
```

---

## Task 2: Unit test — MapManager throws RuntimeException for unmapped class

**Target:** `app/src/Mapper/MapManager.php` line 25 — `throw new \RuntimeException(...)`.

**Why it is uncovered:** The container always injects all registered mappers. No existing test calls `getMapper()` with an unknown class.

**New file:** `app/tests/Unit/Mapper/MapManagerTest.php`

### Steps

- [ ] Create the directory `app/tests/Unit/Mapper/` if it does not exist.

- [ ] Create `app/tests/Unit/Mapper/MapManagerTest.php`:

```php
<?php

declare(strict_types=1);

namespace App\Tests\Unit\Mapper;

use App\Mapper\MapManager;
use PHPUnit\Framework\TestCase;

class MapManagerTest extends TestCase
{
    public function testGetMapperThrowsRuntimeExceptionForUnmappedClass(): void
    {
        $manager = new MapManager(new \ArrayIterator([]));

        $this->expectException(\RuntimeException::class);
        $this->expectExceptionMessage('No mapper found for: App\SomeUnknownResource');

        $manager->getMapper('App\SomeUnknownResource');
    }
}
```

- [ ] Run the test:

```sh
docker compose exec php php bin/phpunit tests/Unit/Mapper/MapManagerTest.php
```

Expected: 1 test, 1 assertion, green. `MapManager` line 25 is now covered.

- [ ] Commit:

```sh
git add app/tests/Unit/Mapper/MapManagerTest.php
git commit -m "test: cover RuntimeException branch in MapManager::getMapper()"
```

---

## Task 3: Unit test — MappedPaginator methods

**Target:** `app/src/State/Pagination/MappedPaginator.php` — all uncovered lines:
- `getCurrentPage()` (0%)
- `getItemsPerPage()` (0%)
- `getLastPage()` zero-items and zero-perpage branches (66%)
- `getIterator()` foreach body (50%)
- `count()` (0%)

**New file:** `app/tests/Unit/State/MappedPaginatorTest.php`

### Notes on mocking

`Doctrine\ORM\Tools\Pagination\Paginator` is a concrete class. PHPUnit's `createMock` generates a subclass, which is sufficient. Its `count()` method is called in the `MappedPaginator` constructor (via PHP's `count()`). Stub it to return the desired integer.

For `getIterator()`, the `DoctrinePaginator` implements `\IteratorAggregate`. Stub `getIterator()` on the mock to return an `\ArrayIterator` containing one fake entity object.

### Steps

- [ ] Create the directory `app/tests/Unit/State/` if it does not exist.

- [ ] Create `app/tests/Unit/State/MappedPaginatorTest.php`:

```php
<?php

declare(strict_types=1);

namespace App\Tests\Unit\State;

use App\Mapper\EntityMapperInterface;
use App\State\Pagination\MappedPaginator;
use Doctrine\ORM\Tools\Pagination\Paginator as DoctrinePaginator;
use PHPUnit\Framework\TestCase;

class MappedPaginatorTest extends TestCase
{
    private function makeDoctrinePaginatorMock(int $totalItems, array $entities = []): DoctrinePaginator
    {
        $mock = $this->createMock(DoctrinePaginator::class);
        $mock->method('count')->willReturn($totalItems);
        $mock->method('getIterator')->willReturn(new \ArrayIterator($entities));
        return $mock;
    }

    private function makeMapperMock(?object $returnValue = null): EntityMapperInterface
    {
        $mock = $this->createMock(EntityMapperInterface::class);
        if ($returnValue !== null) {
            $mock->method('toResource')->willReturn($returnValue);
        }
        return $mock;
    }

    public function testGetCurrentPageReturnsFloat(): void
    {
        $paginator = new MappedPaginator(
            $this->makeDoctrinePaginatorMock(10),
            $this->makeMapperMock(),
            currentPage: 3,
            itemsPerPage: 10,
        );

        $this->assertSame(3.0, $paginator->getCurrentPage());
    }

    public function testGetItemsPerPageReturnsFloat(): void
    {
        $paginator = new MappedPaginator(
            $this->makeDoctrinePaginatorMock(10),
            $this->makeMapperMock(),
            currentPage: 1,
            itemsPerPage: 25,
        );

        $this->assertSame(25.0, $paginator->getItemsPerPage());
    }

    public function testGetLastPageNormalCase(): void
    {
        // 25 items, 10 per page → ceil(25/10) = 3.0
        $paginator = new MappedPaginator(
            $this->makeDoctrinePaginatorMock(25),
            $this->makeMapperMock(),
            currentPage: 1,
            itemsPerPage: 10,
        );

        $this->assertSame(3.0, $paginator->getLastPage());
    }

    public function testGetLastPageReturnsOneWhenTotalItemsIsZero(): void
    {
        $paginator = new MappedPaginator(
            $this->makeDoctrinePaginatorMock(0),
            $this->makeMapperMock(),
            currentPage: 1,
            itemsPerPage: 10,
        );

        $this->assertSame(1.0, $paginator->getLastPage());
    }

    public function testGetLastPageReturnsOneWhenItemsPerPageIsZero(): void
    {
        $paginator = new MappedPaginator(
            $this->makeDoctrinePaginatorMock(10),
            $this->makeMapperMock(),
            currentPage: 1,
            itemsPerPage: 0,
        );

        $this->assertSame(1.0, $paginator->getLastPage());
    }

    public function testGetTotalItemsReturnsFloat(): void
    {
        $paginator = new MappedPaginator(
            $this->makeDoctrinePaginatorMock(42),
            $this->makeMapperMock(),
            currentPage: 1,
            itemsPerPage: 10,
        );

        $this->assertSame(42.0, $paginator->getTotalItems());
    }

    public function testCountReturnsInt(): void
    {
        $paginator = new MappedPaginator(
            $this->makeDoctrinePaginatorMock(7),
            $this->makeMapperMock(),
            currentPage: 1,
            itemsPerPage: 10,
        );

        $this->assertSame(7, $paginator->count());
    }

    public function testGetIteratorYieldsMappedDtos(): void
    {
        $fakeEntity = new \stdClass();
        $fakeDto = new \stdClass();
        $fakeDto->name = 'mapped';

        $mapper = $this->createMock(EntityMapperInterface::class);
        $mapper->expects($this->once())
            ->method('toResource')
            ->with($this->identicalTo($fakeEntity))
            ->willReturn($fakeDto);

        $paginator = new MappedPaginator(
            $this->makeDoctrinePaginatorMock(1, [$fakeEntity]),
            $mapper,
            currentPage: 1,
            itemsPerPage: 10,
        );

        $results = iterator_to_array($paginator->getIterator());

        $this->assertCount(1, $results);
        $this->assertSame($fakeDto, $results[0]);
    }
}
```

- [ ] Run the tests:

```sh
docker compose exec php php bin/phpunit tests/Unit/State/MappedPaginatorTest.php
```

Expected: 8 tests, all green. All previously uncovered `MappedPaginator` lines are now covered.

- [ ] Commit:

```sh
git add app/tests/Unit/State/MappedPaginatorTest.php
git commit -m "test: cover all uncovered MappedPaginator methods including zero-item and zero-perpage branches"
```

---

## Task 4: Integration test — BookRepository::findAvailable()

**Target:** `app/src/Repository/BookRepository.php` — the entire `findAvailable()` method (6 uncovered lines).

**Why it is uncovered:** No test calls this method. It is a query-builder method and must be tested against a real database.

**New file:** `app/tests/Integration/Repository/BookRepositoryTest.php`

### Steps

- [ ] Create the directory `app/tests/Integration/Repository/` if it does not exist.

- [ ] Create `app/tests/Integration/Repository/BookRepositoryTest.php`:

```php
<?php

declare(strict_types=1);

namespace App\Tests\Integration\Repository;

use App\Entity\Book;
use App\Repository\BookRepository;
use Doctrine\ORM\EntityManagerInterface;
use Symfony\Bundle\FrameworkBundle\Test\KernelTestCase;

class BookRepositoryTest extends KernelTestCase
{
    private EntityManagerInterface $em;
    private BookRepository $repository;

    protected function setUp(): void
    {
        self::bootKernel();
        $this->em = static::getContainer()->get(EntityManagerInterface::class);
        $this->repository = static::getContainer()->get(BookRepository::class);
        $this->em->createQuery('DELETE FROM App\Entity\Book b')->execute();
    }

    protected function tearDown(): void
    {
        $this->em->createQuery('DELETE FROM App\Entity\Book b')->execute();
        parent::tearDown();
    }

    private function createBook(string $title, string $isbn, bool $available): Book
    {
        $book = new Book();
        $book->setTitle($title);
        $book->setIsbn($isbn);
        $book->setAuthorName('Test Author');
        $book->setAvailable($available);
        $this->em->persist($book);
        $this->em->flush();
        return $book;
    }

    public function testFindAvailableReturnsOnlyAvailableBooks(): void
    {
        $this->createBook('Alpha Book', '9780743273565', true);
        $this->createBook('Beta Book', '9780451524935', true);
        $this->createBook('Unavailable Book', '9780061965487', false);

        $results = $this->repository->findAvailable();

        $this->assertCount(2, $results);
    }

    public function testFindAvailableReturnsBooksInTitleAscOrder(): void
    {
        $this->createBook('Zebra Book', '9780743273565', true);
        $this->createBook('Alpha Book', '9780451524935', true);

        $results = $this->repository->findAvailable();

        $this->assertCount(2, $results);
        $this->assertSame('Alpha Book', $results[0]->getTitle());
        $this->assertSame('Zebra Book', $results[1]->getTitle());
    }

    public function testFindAvailableReturnsEmptyArrayWhenNoBooksAvailable(): void
    {
        $this->createBook('Unavailable Book', '9780743273565', false);

        $results = $this->repository->findAvailable();

        $this->assertSame([], $results);
    }
}
```

- [ ] Run the tests:

```sh
docker compose exec php php bin/phpunit tests/Integration/Repository/BookRepositoryTest.php
```

Expected: 3 tests, all green. All 6 uncovered lines in `findAvailable()` are now covered.

- [ ] Commit:

```sh
git add app/tests/Integration/Repository/BookRepositoryTest.php
git commit -m "test: cover BookRepository::findAvailable() with integration tests"
```

---

## Task 5: Unit test — EntityInsertEventListener uncovered branches

**Target:** `app/src/EventListener/Doctrine/EntityInsertEventListener.php` — lines 36-38 (`class_exists` false branch in `prePersist`) and lines 56-58 (`class_exists` false branch in `postPersist`).

**Coverage strategy:**

The event class name is resolved by convention: `App\Event\{EntityName}ChangeEvent`. To trigger the `class_exists` false branch, a stub entity class must have a name that does NOT match any existing event class. A class named `FakeInsertableEntity` in the test namespace resolves to `App\Event\FakeInsertableEntityChangeEvent`, which does not exist — so the listener returns early without dispatching.

**Branch C note:** The "event exists but doesn't implement the right interface" branch (lines 41-43 in `prePersist`, 61-63 in `postPersist`) requires a real class registered as `App\Event\FakeXxxChangeEvent`. This cannot be easily achieved without either modifying the autoloader or creating a production-namespace file in the test tree. This branch is documented as **not feasible to test in isolation** and is excluded from this task. The 4 remaining lines (one per `class_exists` guard per method across the two methods) are covered by branch B.

**New file:** `app/tests/Unit/EventListener/EntityInsertEventListenerTest.php`

### Steps

- [ ] Create the directory `app/tests/Unit/EventListener/` if it does not exist.

- [ ] Create `app/tests/Unit/EventListener/EntityInsertEventListenerTest.php`:

```php
<?php

declare(strict_types=1);

namespace App\Tests\Unit\EventListener;

use App\EventListener\Doctrine\EntityInsertEventListener;
use App\EventListener\Doctrine\Interface\NotifiableInsertInterface;
use Doctrine\ORM\Event\PostPersistEventArgs;
use Doctrine\ORM\Event\PrePersistEventArgs;
use PHPUnit\Framework\TestCase;
use Symfony\Component\EventDispatcher\EventDispatcherInterface;

class EntityInsertEventListenerTest extends TestCase
{
    private EventDispatcherInterface $dispatcher;
    private EntityInsertEventListener $listener;

    protected function setUp(): void
    {
        $this->dispatcher = $this->createMock(EventDispatcherInterface::class);
        $this->listener = new EntityInsertEventListener($this->dispatcher);
    }

    // Branch B: entity implements NotifiableInsertInterface but event class does not exist.
    // FakeInsertableEntity resolves to App\Event\FakeInsertableEntityChangeEvent (does not exist).

    public function testPrePersistDoesNotDispatchWhenEventClassDoesNotExist(): void
    {
        $entity = new FakeInsertableEntity();

        $args = $this->createMock(PrePersistEventArgs::class);
        $args->method('getObject')->willReturn($entity);

        $this->dispatcher->expects($this->never())->method('dispatch');

        $this->listener->prePersist($args);
    }

    public function testPostPersistDoesNotDispatchWhenEventClassDoesNotExist(): void
    {
        $entity = new FakeInsertableEntity();

        $args = $this->createMock(PostPersistEventArgs::class);
        $args->method('getObject')->willReturn($entity);

        $this->dispatcher->expects($this->never())->method('dispatch');

        $this->listener->postPersist($args);
    }

    // Sanity: entity does not implement NotifiableInsertInterface → returns early (already covered elsewhere,
    // but included here to make the test class self-contained).

    public function testPrePersistDoesNotDispatchWhenEntityIsNotNotifiable(): void
    {
        $entity = new \stdClass();

        $args = $this->createMock(PrePersistEventArgs::class);
        $args->method('getObject')->willReturn($entity);

        $this->dispatcher->expects($this->never())->method('dispatch');

        $this->listener->prePersist($args);
    }

    public function testPostPersistDoesNotDispatchWhenEntityIsNotNotifiable(): void
    {
        $entity = new \stdClass();

        $args = $this->createMock(PostPersistEventArgs::class);
        $args->method('getObject')->willReturn($entity);

        $this->dispatcher->expects($this->never())->method('dispatch');

        $this->listener->postPersist($args);
    }
}

/**
 * Stub entity that implements NotifiableInsertInterface.
 * Its class name resolves to App\Event\FakeInsertableEntityChangeEvent,
 * which does not exist — so the class_exists guard returns false.
 */
class FakeInsertableEntity implements NotifiableInsertInterface {}
```

- [ ] Run the tests:

```sh
docker compose exec php php bin/phpunit tests/Unit/EventListener/EntityInsertEventListenerTest.php
```

Expected: 4 tests, all green. `class_exists` false branches (lines 36-38 and 56-58) are now covered.

- [ ] Commit:

```sh
git add app/tests/Unit/EventListener/EntityInsertEventListenerTest.php
git commit -m "test: cover class_exists false branches in EntityInsertEventListener"
```

---

## Task 6: Unit test — EntityUpdatedEventListener uncovered branches

**Target:** `app/src/EventListener/Doctrine/EntityUpdatedEventListener.php` — lines 37-39 (`class_exists` false branch in `preUpdate`) and lines 58-60 (`class_exists` false branch in `postUpdate`).

**Coverage strategy:** Mirror Task 5. A `FakeUpdatableEntity` class implementing `NotifiableUpdatedInterface` resolves to `App\Event\FakeUpdatableEntityChangeEvent`, which does not exist.

**Branch C note:** Same constraint as Task 5 — the "event exists but wrong interface" branch is excluded as not feasible without production-namespace file creation.

**Note on `PreUpdateEventArgs`:** Doctrine's `PreUpdateEventArgs` carries change-set data in its constructor. Mocking it with `createMock` bypasses the constructor and is the correct approach — only `getObject()` needs to be stubbed.

**New file:** `app/tests/Unit/EventListener/EntityUpdatedEventListenerTest.php`

### Steps

- [ ] Create `app/tests/Unit/EventListener/EntityUpdatedEventListenerTest.php`:

```php
<?php

declare(strict_types=1);

namespace App\Tests\Unit\EventListener;

use App\EventListener\Doctrine\EntityUpdatedEventListener;
use App\EventListener\Doctrine\Interface\NotifiableUpdatedInterface;
use Doctrine\ORM\Event\PostUpdateEventArgs;
use Doctrine\ORM\Event\PreUpdateEventArgs;
use PHPUnit\Framework\TestCase;
use Symfony\Component\EventDispatcher\EventDispatcherInterface;

class EntityUpdatedEventListenerTest extends TestCase
{
    private EventDispatcherInterface $dispatcher;
    private EntityUpdatedEventListener $listener;

    protected function setUp(): void
    {
        $this->dispatcher = $this->createMock(EventDispatcherInterface::class);
        $this->listener = new EntityUpdatedEventListener($this->dispatcher);
    }

    // Branch B: entity implements NotifiableUpdatedInterface but event class does not exist.
    // FakeUpdatableEntity resolves to App\Event\FakeUpdatableEntityChangeEvent (does not exist).

    public function testPreUpdateDoesNotDispatchWhenEventClassDoesNotExist(): void
    {
        $entity = new FakeUpdatableEntity();

        $args = $this->createMock(PreUpdateEventArgs::class);
        $args->method('getObject')->willReturn($entity);

        $this->dispatcher->expects($this->never())->method('dispatch');

        $this->listener->preUpdate($args);
    }

    public function testPostUpdateDoesNotDispatchWhenEventClassDoesNotExist(): void
    {
        $entity = new FakeUpdatableEntity();

        $args = $this->createMock(PostUpdateEventArgs::class);
        $args->method('getObject')->willReturn($entity);

        $this->dispatcher->expects($this->never())->method('dispatch');

        $this->listener->postUpdate($args);
    }

    // Sanity: entity does not implement NotifiableUpdatedInterface → returns early.

    public function testPreUpdateDoesNotDispatchWhenEntityIsNotNotifiable(): void
    {
        $entity = new \stdClass();

        $args = $this->createMock(PreUpdateEventArgs::class);
        $args->method('getObject')->willReturn($entity);

        $this->dispatcher->expects($this->never())->method('dispatch');

        $this->listener->preUpdate($args);
    }

    public function testPostUpdateDoesNotDispatchWhenEntityIsNotNotifiable(): void
    {
        $entity = new \stdClass();

        $args = $this->createMock(PostUpdateEventArgs::class);
        $args->method('getObject')->willReturn($entity);

        $this->dispatcher->expects($this->never())->method('dispatch');

        $this->listener->postUpdate($args);
    }
}

/**
 * Stub entity that implements NotifiableUpdatedInterface.
 * Its class name resolves to App\Event\FakeUpdatableEntityChangeEvent,
 * which does not exist — so the class_exists guard returns false.
 */
class FakeUpdatableEntity implements NotifiableUpdatedInterface {}
```

- [ ] Run the tests:

```sh
docker compose exec php php bin/phpunit tests/Unit/EventListener/EntityUpdatedEventListenerTest.php
```

Expected: 4 tests, all green. `class_exists` false branches (lines 37-39 and 58-60) are now covered.

- [ ] Commit:

```sh
git add app/tests/Unit/EventListener/EntityUpdatedEventListenerTest.php
git commit -m "test: cover class_exists false branches in EntityUpdatedEventListener"
```

---

## Final verification

Run the full test suite with coverage to confirm overall improvement:

```sh
docker compose exec php php bin/phpunit --coverage-text
```

Expected: all existing 15 tests still pass, plus 2 (Task 1) + 1 (Task 2) + 8 (Task 3) + 3 (Task 4) + 4 (Task 5) + 4 (Task 6) = 22 new tests, for 37 total. Coverage for the targeted classes rises to near 100% (excluding the documented branch-C lines in the event listeners).

---

## Coverage summary

| Class | Before | After | Notes |
|---|---|---|---|
| `GenericDtoProcessor` | ~95% | 100% | `ItemNotFoundException` branch covered |
| `MapManager` | ~90% | 100% | `RuntimeException` branch covered |
| `MappedPaginator` | ~50% | 100% | All methods covered, both `getLastPage` branches |
| `BookRepository` | ~67% | 100% | `findAvailable()` covered via integration test |
| `EntityInsertEventListener` | 71% | ~86% | `class_exists` false branch covered; branch C (wrong interface) excluded |
| `EntityUpdatedEventListener` | 71% | ~86% | `class_exists` false branch covered; branch C (wrong interface) excluded |

### Branch C exclusion rationale

Lines 41-43 in `EntityInsertEventListener::prePersist` and 61-63 in `postPersist` (and their equivalents in `EntityUpdatedEventListener`) require a class to exist at runtime under `App\Event\{EntityName}ChangeEvent` that does NOT implement `PreChangeEventInterface` or `PostChangeEventInterface`. Achieving this without creating a permanently registered production-namespace class (which would pollute the real event namespace) or modifying the autoloader configuration is not feasible. These 4 lines across 2 files can be covered in a future task if the event resolution logic is refactored to be injectable/mockable.
