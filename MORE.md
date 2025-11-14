# Core Concepts

Docs: [API Platform Documentation](https://api-platform.com/docs/)

 - ApiResource - Defines the endpoint structure (entity or DTO)
 - StateProvider - To retrieve data exposed by the API
 - StateProcessor - Mutates application state during POST, PUT, PATCH or DELETE operations
 - Validation
 - Security Voters - The easiest and recommended way to hook custom access control logic
 - Filters

 ## 1. ApiResource

#### **`src/Entity/Folder.php`**
 ```php 
<?php

namespace App\Entity;

use ApiPlatform\Metadata\ApiResource;

#[ApiResource]
class Folder
{ 
    //... 
}
 ```

#### **`scr/ApiResource/Folder.php`**
 ```php 
<?php

namespace App\ApiResource;

use ApiPlatform\Metadata\ApiProperty;
use ApiPlatform\Metadata\ApiResource;

#[ApiResource(
    shortName: 'File',
    description: 'A File'
)]
class File
{
    #[ApiProperty(identifier: true)]
    public int $id;
}
 ```

### Endpoint scope


#### **`src/Entity/Folder.php`**
```php
<?php

namespace App\Entity;

use ApiPlatform\Metadata\ApiResource;
use ApiPlatform\Metadata\Get;
use ApiPlatform\Metadata\GetCollection;

#[ApiResource(
    description: 'A folder',
    operations: [
        new Get(),
        new GetCollection()
    ],
    routePrefix: '/disk',
)]
class Folder
{
    // ...
}
```

#### **`src/Entity/Folder.php`**
```php
<?php

namespace App\Entity;

use Symfony\Component\Serializer\Annotation\Groups;
use Symfony\Component\Serializer\Annotation\Ignore;

#[ApiResource(
    normalizationContext: ['groups' => ['product:read']],
    denormalizationContext: ['groups' => ['product:write']]
)]
class Folder
{
    #[Groups(['product:read', 'product:write'])]
    private ?string $name = null;

    #[Groups(['product:read'])]
    private ?\DateTimeImmutable $createdAt = null;

    #[Ignore]
    private ?string $description = null;

    #[ApiProperty(readable: false)]
    private ?\DateTimeImmutable $updatedAt = null;
```


### Supported output formats

#### **`config/packages/api_platform.yaml`**
```yaml
api_platform:
    formats:
      jsonld: [ 'application/ld+json' ]
      json: [ 'application/json' ]
      csv: [ 'text/csv' ]
      xml:	['application/xml']
```

## 2. StateProvider

To retrieve data exposed by the API - used during `GET` calls

#### **`src/Entity/Folder.php`**
```php
<?php

namespace App\Entity;

use ApiPlatform\Metadata\ApiResource;

use App\State\FolderStateProvider;

#[ApiResource(
    provider: FolderStateProvider::class,
)]
class Folder
{
    /// ....
}
```

#### **`src/State/FolderStateProvider.php`**

```php
<?php

namespace App\State;

use ApiPlatform\Metadata\Operation;
use ApiPlatform\State\ProviderInterface;
use ApiPlatform\Metadata\CollectionOperationInterface;

class FolderStateProvider implements ProviderInterface
{
    public function provide(Operation $operation, array $uriVariables = [], array $context = []): object|array|null
    {
        if ($operation instanceof CollectionOperationInterface) {
            return $this->getPaginatedCollection($context, $operation);
        }

        return $this->getItem($uriVariables['id']);
    }
}
```

## 3. StateProcessor

Mutates application state during `POST`, `PUT`, `PATCH` or `DELETE` operations

#### **`src/Entity/Folder.php`**
```php
<?php

namespace App\Entity;

use ApiPlatform\Metadata\ApiResource;

use App\State\FolderStateProcessor;

#[ApiResource(
    processor: FolderStateProcessor::class,
)]
class Folder
{
    /// ....
}
```

#### **`src/State/FolderStateProcessor.php`**

```php
<?php

namespace App\State;

use ApiPlatform\Metadata\Operation;
use ApiPlatform\State\ProcessorInterface;
use ApiPlatform\Metadata\DeleteOperationInterface;

class FolderStateProcessor implements ProcessorInterface
{
    public function process(mixed $data, Operation $operation, array $uriVariables = [], array $context = []): mixed
    {
        if ($operation instanceof DeleteOperationInterface) {
            // Handle deletion
            return null;
        }

        // persist/update data
        return $data;
    }
}
```

## 4. Validation

#### **`src/Entity/Folder.php`**

```php
<?php

namespace App\Entity;

use ApiPlatform\Metadata\ApiResource;
use Symfony\Component\Validator\Constraints as Assert;

#[ApiResource]
class Folder
{
    #[Assert\NotBlank]
    #[Assert\Length(min: 3, max: 255)]
    private ?string $name = null;

    #[Assert\Length(max: 512)]
    private ?string $description = null;

    #[Assert\NotBlank]
    #[Assert\Date]
    private ?\DateTimeImmutable $createdAt = null;
}
```

### Custom validator

#### **`src/Entity/Folder.php`**

```php
<?php

namespace App\Entity;

use ApiPlatform\Metadata\ApiResource;
use App\Validator\Constraints as CustomAssert;

#[ApiResource]
#[CustomAssert\CreatedAtDate()]
class Folder
{
    // ...
}
```

#### **`src/Validator/Constraints/CreatedAtDate.php`**

```php
<?php
namespace App\Validator\Constraints;

use Symfony\Component\Validator\Attribute\HasNamedArguments;
use Symfony\Component\Validator\Constraint;

#[\Attribute]
class CreatedAtDate extends Constraint
{
    public string $message = 'created_at_date_conflict';s

    #[HasNamedArguments]
    public function __construct(?string $message = null)
    {
        if ($message) {
            $this->message = $message;
        }
        parent::__construct();
    }

    public function getTargets(): string
    {
        return self::CLASS_CONSTRAINT;
    }
}
```

#### **`src/Validator/Constraints/CreatedAtDateValidator.php`**

```php
<?php
namespace App\Validator\Constraints;

use Symfony\Component\Validator\Constraint;
use Symfony\Component\Validator\ConstraintValidator;
use Symfony\Component\Validator\Exception\UnexpectedTypeException;
use Symfony\Component\Validator\Exception\UnexpectedValueException;
use App\Entity\Folder;

class CreatedAtDateValidator extends ConstraintValidator
{
    public function validate($value, Constraint $constraint)
    {   
        if (null === $value || '' === $value) {
            return;
        }

       if (!$constraint instanceof CreatedAtDate) {
            throw new UnexpectedTypeException($constraint, CreatedAtDate::class);
        }

        if (!$value instanceof Folder) {
            throw new UnexpectedValueException($value, 'Not instance of Folder');
        }

        if ($value->getCreatedAt()->format('U') < time() && is_null($value->getId())) {
            $this->context->buildViolation('Creation date in the past')
                ->atPath('createdAt')
                ->addViolation();
        }
    }
}
```
