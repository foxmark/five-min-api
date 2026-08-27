# Entity > Mapper > DTO Pattern — LLM Replication Prompt

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement a new API resource called `[EntityName]` (replace every occurrence of `Book`/`book` with your entity name) following the Entity > Mapper > DTO pattern used throughout this codebase.

**Architecture:** The API layer (DTO/ApiResource) is decoupled from the persistence layer (Doctrine Entity) by a Mapper. The generic state provider and processor handle all HTTP operations automatically — you only register a new Mapper and the infrastructure does the rest. Domain events fire around persistence via Doctrine lifecycle listeners, decoupled from the entity itself.

**Tech Stack:** Symfony 7.4, API Platform 4.x, Doctrine ORM, PHP 8.2+

---

## Pattern Overview

Each domain resource requires exactly **six files**. The infrastructure classes below already exist — do not recreate them:

| Existing infrastructure | Role |
|---|---|
| `src/State/Provider/GenericDtoProvider.php` | Handles GET + GetCollection for all resources |
| `src/State/Processor/GenericDtoProcessor.php` | Handles POST/PUT/PATCH/DELETE for all resources |
| `src/Mapper/MapManager.php` | Auto-discovers mappers tagged with `EntityMapperInterface::TAG` |
| `src/State/Pagination/MappedPaginator.php` | Wraps Doctrine paginator, yields DTOs |
| `src/Mapper/EntityMapperInterface.php` | Contract all mappers must implement |
| `src/Repository/DefaultOrderRepositoryInterface.php` | Default ORDER BY contract for repositories |
| `src/EventListener/Doctrine/EntityInsertEventListener.php` | Dispatches pre/post-create events around `prePersist`/`postPersist` |
| `src/EventListener/Doctrine/EntityUpdatedEventListener.php` | Dispatches pre/post-update events around `preUpdate`/`postUpdate` |
| `src/EventListener/Doctrine/Trait/DoctrineEventListenerTrait.php` | Derives the event class name from the entity class name |
| `src/EventListener/Doctrine/Interface/NotifiableInsertInterface.php` | Marker: entity wants pre/post-create events |
| `src/EventListener/Doctrine/Interface/NotifiableUpdatedInterface.php` | Marker: entity wants pre/post-update events |
| `src/Event/ChangeEventInterface.php` | Base contract: `getEntityClassName(): string` |
| `src/Event/PreChangeEventInterface.php` | Contract: `getPreCreateEventName()`, `getPreUpdateEventName()` |
| `src/Event/PostChangeEventInterface.php` | Contract: `getPostCreateEventName()`, `getPostUpdateEventName()` |
| `src/Event/Trait/EntityEventTrait.php` | Default implementation of all four event-name methods, derived from `getEntityClassName()` |

**Critical naming rule:** `DoctrineEventListenerTrait::getEventClassName($entity)` auto-derives the event class as `App\Event\{EntityShortName}ChangeEvent` (e.g. `Book` → `App\Event\BookChangeEvent`). The event class MUST live at this exact FQCN or events will silently not fire (the listener does a `class_exists` check and returns early if it's missing — no error is raised).

---

## File Structure

| File | Action |
|---|---|
| `src/Entity/Book.php` | Create |
| `src/ApiResource/BookResource.php` | Create |
| `src/Mapper/BookMapper.php` | Create |
| `src/Repository/BookRepository.php` | Create |
| `src/Event/BookChangeEvent.php` | Create |
| `src/EventSubscriber/BookEventSubscriber.php` | Create |

---

## Task 1: Doctrine Entity

**Files:**
- Create: `src/Entity/Book.php`

- [ ] **Step 1: Write the entity class**

```php
<?php

namespace App\Entity;

use App\Repository\BookRepository;
use DateTimeImmutable;
use Doctrine\ORM\Mapping as ORM;
use App\EventListener\Doctrine\Interface\NotifiableInsertInterface;
use App\EventListener\Doctrine\Interface\NotifiableUpdatedInterface;

#[ORM\Entity(repositoryClass: BookRepository::class)]
#[ORM\Table(name: 'book')]
#[ORM\HasLifecycleCallbacks]
class Book implements NotifiableInsertInterface, NotifiableUpdatedInterface
{
    #[ORM\Id]
    #[ORM\GeneratedValue]
    #[ORM\Column(type: 'integer')]
    private ?int $id = null;

    #[ORM\Column(type: 'string', length: 255)]
    private string $title = '';

    #[ORM\Column(type: 'string', length: 20, unique: true)]
    private string $isbn = '';

    #[ORM\Column(type: 'string', length: 255)]
    private string $authorName = '';

    #[ORM\Column(type: 'datetime_immutable', nullable: true)]
    private ?DateTimeImmutable $publishedAt = null;

    #[ORM\Column(type: 'boolean', options: ['default' => true])]
    private bool $available = true;

    #[ORM\Column(type: 'datetime_immutable')]
    private DateTimeImmutable $createdAt;

    #[ORM\PrePersist]
    public function initTimestamps(): void
    {
        $this->createdAt = new DateTimeImmutable();
    }

    public function getId(): ?int { return $this->id; }

    public function getTitle(): string { return $this->title; }
    public function setTitle(string $title): void { $this->title = $title; }

    public function getIsbn(): string { return $this->isbn; }
    public function setIsbn(string $isbn): void { $this->isbn = $isbn; }

    public function getAuthorName(): string { return $this->authorName; }
    public function setAuthorName(string $authorName): void { $this->authorName = $authorName; }

    public function getPublishedAt(): ?DateTimeImmutable { return $this->publishedAt; }
    public function setPublishedAt(?DateTimeImmutable $publishedAt): void { $this->publishedAt = $publishedAt; }

    public function isAvailable(): bool { return $this->available; }
    public function setAvailable(bool $available): void { $this->available = $available; }

    public function getCreatedAt(): DateTimeImmutable { return $this->createdAt; }
}
```

**Rules:**
- Implement `NotifiableInsertInterface` if you want `prePersist`/`postPersist` events; implement `NotifiableUpdatedInterface` if you want `preUpdate`/`postUpdate` events. They're independent — an entity can implement either, both, or neither.
- Add `#[ORM\PrePersist]` on `initTimestamps()` to set `createdAt` automatically.
- Use `#[ORM\HasLifecycleCallbacks]` on the class.
- Properties that differ from the DTO (e.g., `publishedAt` as `DateTimeImmutable` vs `publicationYear` as `int`) are resolved in the Mapper, not here.
- No validation constraints on the entity — those belong on the DTO (Task 2).

- [ ] **Step 2: Generate and run the migration**

```bash
docker compose exec php symfony console make:migration
docker compose exec php symfony console doctrine:migrations:migrate
```

Expected: migration file created, schema updated with `book` table.

- [ ] **Step 3: Commit**

```bash
git add src/Entity/Book.php migrations/
git commit -m "feat: add Book entity"
```

---

## Task 2: API Resource (DTO)

**Files:**
- Create: `src/ApiResource/BookResource.php`

- [ ] **Step 1: Write the DTO class**

```php
<?php
// src/ApiResource/BookResource.php

namespace App\ApiResource;

use ApiPlatform\Metadata\ApiResource;
use ApiPlatform\Metadata\Delete;
use ApiPlatform\Metadata\Get;
use ApiPlatform\Metadata\GetCollection;
use ApiPlatform\Metadata\Patch;
use ApiPlatform\Metadata\Post;
use ApiPlatform\Metadata\Put;
use App\State\Processor\GenericDtoProcessor;
use App\State\Provider\GenericDtoProvider;
use Symfony\Component\Validator\Constraints as Assert;

#[ApiResource(
    shortName: 'Book',
    operations: [
        new GetCollection(provider: GenericDtoProvider::class),
        new Get(provider: GenericDtoProvider::class),
        new Post(processor: GenericDtoProcessor::class),
        new Put(provider: GenericDtoProvider::class, processor: GenericDtoProcessor::class),
        new Patch(provider: GenericDtoProvider::class, processor: GenericDtoProcessor::class),
        new Delete(provider: GenericDtoProvider::class, processor: GenericDtoProcessor::class),
    ],
    paginationEnabled: true,
    paginationItemsPerPage: 10,
    paginationClientItemsPerPage: true,
    paginationMaximumItemsPerPage: 30,
)]
class BookResource
{
    public ?int $id = null;

    #[Assert\NotBlank]
    #[Assert\Length(min: 2, max: 255)]
    public ?string $title = null;

    #[Assert\NotBlank]
    #[Assert\Isbn]
    public ?string $isbn = null;

    #[Assert\NotBlank]
    public ?string $authorName = null;

    #[Assert\Range(min: 1000, max: 2100)]
    public ?int $publicationYear = null;

    public bool $available = true;
}
```

**Rules:**
- Always wire `GenericDtoProvider` to GET/GetCollection and `GenericDtoProcessor` to write operations.
- Put, Patch, and Delete must also specify `provider:` — `GenericDtoProcessor` needs the *existing* entity loaded (via the mapper + repository) before it can update or delete it; without a provider on those operations, API Platform won't fetch it.
- Validation constraints go on the DTO, never on the entity.
- `id` is always `public ?int $id = null;` — it is set by the mapper on read and ignored on write.
- The DTO may expose a different field shape than the entity (e.g., `publicationYear: int` instead of `publishedAt: DateTimeImmutable`). The Mapper (Task 3) handles the translation both ways.
- Bool fields on the DTO are never nullable — always `public bool $x = <default>;`.

- [ ] **Step 2: Verify the route is registered**

```bash
docker compose exec php symfony console debug:router | grep book
```

Expected: lines for `api_books_get_collection`, `api_books_post`, `api_books_get`, `api_books_put`, `api_books_patch`, `api_books_delete`.

- [ ] **Step 3: Commit**

```bash
git add src/ApiResource/BookResource.php
git commit -m "feat: add BookResource DTO"
```

---

## Task 3: Mapper

**Files:**
- Create: `src/Mapper/BookMapper.php`

- [ ] **Step 1: Write the mapper class**

```php
<?php

namespace App\Mapper;

use App\ApiResource\BookResource;
use App\Entity\Book;
use App\Mapper\EntityMapperInterface;
use DateTimeImmutable;

final class BookMapper implements EntityMapperInterface
{
    public function getSupportedResourceClass(): string
    {
        return BookResource::class;
    }

    public function getSupportedEntityClass(): string
    {
        return Book::class;
    }

    public function toResource(object $entity): BookResource
    {
        /** @var Book $entity */
        $resource = new BookResource();

        $resource->id             = $entity->getId();
        $resource->title          = $entity->getTitle();
        $resource->isbn           = $entity->getIsbn();
        $resource->authorName     = $entity->getAuthorName();
        $resource->available      = $entity->isAvailable();

        $resource->publicationYear = $entity->getPublishedAt()?->format('Y')
            ? (int) $entity->getPublishedAt()->format('Y')
            : null;

        return $resource;
    }

    public function toEntity(object $resource, ?object $entity = null): Book
    {
        /** @var BookResource $resource */
        $book = $entity ?? new Book();

        $book->setTitle($resource->title);
        $book->setIsbn($resource->isbn);
        $book->setAuthorName($resource->authorName);
        $book->setAvailable($resource->available);

        $book->setPublishedAt(
            $resource->publicationYear !== null
                ? new DateTimeImmutable(sprintf('%d-01-01', $resource->publicationYear))
                : null
        );

        return $book;
    }
}
```

**Rules:**
- The class MUST implement `EntityMapperInterface`. The `#[AutoconfigureTag(EntityMapperInterface::TAG)]` declared on that interface automatically registers the mapper in `MapManager` — no manual service config needed. `MapManager` keys mappers by `getSupportedResourceClass()`, so this string must be unique per DTO.
- `toEntity()` receives `?object $entity`: non-null on PUT/PATCH (existing entity loaded by the provider), null on POST (new entity). Always do `$entity ?? new Book()`.
- Never set `id` in `toEntity()` — Doctrine manages it.
- Never set `createdAt` in `toEntity()` — the `#[ORM\PrePersist]` lifecycle callback handles it.
- The mapper is the **only** place field-shape differences between DTO and entity are resolved (e.g., `publicationYear` int ↔ `publishedAt` DateTimeImmutable). Keep the entity and DTO themselves free of translation logic.
- `toResource()` is also what `MappedPaginator` calls per-row for `GetCollection`, so it must handle every entity returned by the repository, not just single fetches.

- [ ] **Step 2: Verify mapper is auto-wired**

```bash
docker compose exec php symfony console debug:autowiring | grep BookMapper
```

Expected: `App\Mapper\BookMapper` listed as a tagged service.

- [ ] **Step 3: Commit**

```bash
git add src/Mapper/BookMapper.php
git commit -m "feat: add BookMapper"
```

---

## Task 4: Repository

**Files:**
- Create: `src/Repository/BookRepository.php`

- [ ] **Step 1: Write the repository class**

```php
<?php
// src/Repository/BookRepository.php

namespace App\Repository;

use App\Entity\Book;
use Doctrine\Bundle\DoctrineBundle\Repository\ServiceEntityRepository;
use Doctrine\Persistence\ManagerRegistry;

/**
 * Standard Doctrine repository.
 * Add custom query methods here; keep them out of the entity.
 *
 * @extends ServiceEntityRepository<Book>
 */
class BookRepository extends ServiceEntityRepository implements DefaultOrderRepositoryInterface
{
    public function getDefaultOrder(): array
    {
        return ['id' => 'ASC'];
    }

    public function __construct(ManagerRegistry $registry)
    {
        parent::__construct($registry, Book::class);
    }

    /** @return Book[] Available books ordered by title */
    public function findAvailable(): array
    {
        return $this->createQueryBuilder('b')
            ->andWhere('b.available = :available')
            ->setParameter('available', true)
            ->orderBy('b.title', 'ASC')
            ->getQuery()
            ->getResult();
    }
}
```

**Rules:**
- Always implement `DefaultOrderRepositoryInterface` and return at minimum `['id' => 'ASC']`. `GenericDtoProvider::provide()` checks `$repository instanceof DefaultOrderRepositoryInterface` and, if true, applies each `[field => direction]` pair as an `addOrderBy` on the `GetCollection` query. Without it, collections come back unordered.
- Add domain-specific query methods here (e.g., `findAvailable()`). Keep them out of the entity — the entity should stay a plain data holder plus lifecycle callbacks.

- [ ] **Step 2: Commit**

```bash
git add src/Repository/BookRepository.php
git commit -m "feat: add BookRepository"
```

---

## Task 5: Change Event

**Files:**
- Create: `src/Event/BookChangeEvent.php`

- [ ] **Step 1: Write the event class**

```php
<?php

namespace App\Event;

use App\Entity\Book;
use App\Event\PostChangeEventInterface;
use App\Event\PreChangeEventInterface;
use App\Event\Trait\EntityEventTrait;
use Symfony\Contracts\EventDispatcher\Event;

class BookChangeEvent extends Event implements PostChangeEventInterface, PreChangeEventInterface
{
    use EntityEventTrait;

    private Book $book;

    public function __construct(Book $book)
    {
        $this->book = $book;
    }

    public function getBook(): Book
    {
        return $this->book;
    }

    public static function getEntityClassName(): string
    {
        $parts = explode('\\', Book::class);
        return end($parts);
    }
}
```

**Rules:**
- Class name MUST be `{EntityName}ChangeEvent` in namespace `App\Event\`. `DoctrineEventListenerTrait::getEventClassName($entity)` derives `App\Event\BookChangeEvent` from the entity's runtime class name — any deviation means the listener's `class_exists()` check fails and it silently returns without dispatching anything.
- Constructor MUST accept exactly the entity as its sole argument — the listeners instantiate the event with `new $eventListenerClassName($entity)`.
- Implement `PreChangeEventInterface` and/or `PostChangeEventInterface` depending on which lifecycle hooks you want. Implementing both (as above) is the common case; `use EntityEventTrait;` supplies all four required methods (`getPreCreateEventName`, `getPreUpdateEventName`, `getPostCreateEventName`, `getPostUpdateEventName`) for free, each derived from `getEntityClassName()`.
- `getEntityClassName()` must return the short class name (`'Book'`, not the FQCN and not lowercased) — `EntityEventTrait` builds event names like `Book.post.create`, `Book.pre.update`, etc. from it, and `BookEventSubscriber` (Task 6) must subscribe to those exact, case-sensitive strings.
- Whether pre/post-create events actually fire also depends on the **entity** (Task 1) implementing `NotifiableInsertInterface` (create) / `NotifiableUpdatedInterface` (update) — the event class and the entity marker interface are two independent switches that both need to be "on".

- [ ] **Step 2: Commit**

```bash
git add src/Event/BookChangeEvent.php
git commit -m "feat: add BookChangeEvent"
```

---

## Task 6: Event Subscriber

**Files:**
- Create: `src/EventSubscriber/BookEventSubscriber.php`

- [ ] **Step 1: Write the subscriber class**

```php
<?php

namespace App\EventSubscriber;

use App\Event\BookChangeEvent;
use Psr\Log\LoggerInterface;
use Symfony\Component\DependencyInjection\Attribute\Target;
use Symfony\Component\EventDispatcher\EventSubscriberInterface;

class BookEventSubscriber implements EventSubscriberInterface
{
    public function __construct(
        #[Target('doctrineEntityLogger')]
        private readonly LoggerInterface $logger,
    ) {}

    public static function getSubscribedEvents(): array
    {
        return [
            'Book.post.create' => 'onBookCreated',
            'Book.post.update' => 'onBookUpdated',
            'Book.pre.create'  => 'beforeBookCreate',
            'Book.pre.update'  => 'beforeBookUpdate',
        ];
    }

    public function onBookCreated(BookChangeEvent $event): void
    {
        $book = $event->getBook();
        $this->logger->info('Book created', [
            'entity_class' => $book::class,
            'entity_id'    => $book->getId(),
            'isbn'         => $book->getIsbn(),
            'title'        => $book->getTitle(),
        ]);
    }

    public function onBookUpdated(BookChangeEvent $event): void
    {
        $book = $event->getBook();
        $this->logger->info('Book updated', [
            'entity_class' => $book::class,
            'entity_id'    => $book->getId(),
            'isbn'         => $book->getIsbn(),
            'title'        => $book->getTitle(),
        ]);
    }

    public function beforeBookCreate(BookChangeEvent $event): void
    {
        $book = $event->getBook();
        $this->logger->info('before book created', [
            'entity_class' => $book::class,
            'entity_id'    => $book->getId(),
            'isbn'         => $book->getIsbn(),
            'title'        => $book->getTitle(),
        ]);
    }

    public function beforeBookUpdate(BookChangeEvent $event): void
    {
        $book = $event->getBook();
        $this->logger->info('before book updates', [
            'entity_class' => $book::class,
            'entity_id'    => $book->getId(),
            'isbn'         => $book->getIsbn(),
            'title'        => $book->getTitle(),
        ]);
    }
}
```

**Rules:**
- Subscribe to the string event names produced by `EntityEventTrait`, not to constants — `'{EntityName}.pre.create'`, `'{EntityName}.pre.update'`, `'{EntityName}.post.create'`, `'{EntityName}.post.update'`. Only subscribe to the ones you actually need; omit the rest.
- `id` is `null` on `Book.pre.create` (not yet persisted) and populated on all other events — don't assume `getId()` is set in pre-create handlers.
- The `#[Target('doctrineEntityLogger')]` attribute selects the named logger channel configured in `monolog.yaml`. Use this on the injected `LoggerInterface`.
- Add domain-relevant fields to the log context (e.g., `isbn`, `title`).
- This is the right place to add side-effects on create/update: emails, webhooks, cache invalidation, etc. Use the `pre.*` events for validation/short-circuiting concerns and `post.*` events for side-effects that require the persisted state (e.g. a generated `id`).

- [ ] **Step 2: Smoke-test the full flow**

Create a book via the API and verify the events fire:

```bash
curl -s -X POST http://localhost/api/books \
  -H "Content-Type: application/json" \
  -d '{"title":"Test Book","isbn":"978-3-16-148410-0","authorName":"Jane Doe","publicationYear":2024}' \
  | jq .
```

Expected: `201 Created` with `id` in the response body.

Check the log:

```bash
docker compose exec php tail -20 var/log/dev.log | grep -i "book"
```

Expected: log lines for `before book created` and `Book created`, both carrying the new book's `entity_id`, `isbn`, and `title`.

- [ ] **Step 3: Commit**

```bash
git add src/EventSubscriber/BookEventSubscriber.php
git commit -m "feat: add BookEventSubscriber"
```

---

## Request Lifecycle (how the six files cooperate)

```
GET/GetCollection:
  ApiResource operation → GenericDtoProvider
    → MapManager::getMapper(ResourceClass) → mapper
    → EntityManager->getRepository(mapper->getSupportedEntityClass())
    → (GetCollection: apply DefaultOrderRepositoryInterface ordering + pagination,
       wrap in MappedPaginator which lazily calls mapper->toResource() per row)
    → (Get: repository->find($id), then mapper->toResource())

POST/PUT/PATCH/DELETE:
  ApiResource operation → GenericDtoProcessor
    → MapManager::getMapper(ResourceClass) → mapper
    → (Put/Patch: provider already loaded $existing via repository->find(); reused here)
    → (Delete: repository->find($id) → em->remove() → em->flush(); return null)
    → mapper->toEntity($dto, $existing) → em->persist() → em->flush()
        → Doctrine fires prePersist/postPersist or preUpdate/postUpdate
        → EntityInsertEventListener / EntityUpdatedEventListener check the entity against
          NotifiableInsertInterface / NotifiableUpdatedInterface
        → resolve App\Event\{Entity}ChangeEvent via DoctrineEventListenerTrait, check it's
          class_exists and implements Pre/PostChangeEventInterface, dispatch it
        → {Entity}EventSubscriber handles the named event
    → mapper->toResource($entity) → response DTO
```

**Separation of concerns:**
- **Entity** (`src/Entity`): persistence shape + Doctrine mapping + lifecycle timestamps + which notification marker interfaces it opts into. No validation, no API concerns.
- **ApiResource DTO** (`src/ApiResource`): wire shape + validation constraints + operation/provider/processor wiring. No persistence concerns.
- **Mapper** (`src/Mapper`): the only place translation between the two shapes happens, in both directions. Stateless, tagged, auto-discovered.
- **State Provider/Processor** (`src/State`): generic, resource-agnostic HTTP verb handling. Never touched when adding a new resource.
- **Events** (`src/Event`, `src/EventListener/Doctrine`, `src/EventSubscriber`): decoupled from both the entity and the API layer via Doctrine lifecycle hooks + a naming convention, not direct calls. Side effects (logging, webhooks, etc.) live only in the subscriber.

---

## Substitution Guide

To implement a new entity (e.g., `Author`), replace every occurrence:

| Replace | With |
|---|---|
| `Book` | `Author` |
| `book` (lowercase) | `author` |
| `BookResource` | `AuthorResource` |
| `BookMapper` | `AuthorMapper` |
| `BookRepository` | `AuthorRepository` |
| `BookChangeEvent` | `AuthorChangeEvent` |
| `BookEventSubscriber` | `AuthorEventSubscriber` |
| `Book.pre.create` / `Book.post.create` | `Author.pre.create` / `Author.post.create` |
| `Book.pre.update` / `Book.post.update` | `Author.pre.update` / `Author.post.update` |
| `'book'` (table name) | `'author'` |

Then update the field definitions in each file to match the new entity's data model. The infrastructure (`GenericDtoProvider`, `GenericDtoProcessor`, `MapManager`, the Doctrine event listeners) requires no changes.
