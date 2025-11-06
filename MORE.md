# Part 1: Core Concepts

Docs: [API Platform Documentation](https://api-platform.com/docs/)

 - ApiResource - Defines the endpoint structure (entity or DTO)
 - StateProvider - To retrieve data exposed by the API
 - StateProcessor - Mutates application state during POST, PUT, PATCH or DELETE operations
 - Validation -
 - Security Voters - The easiest and recommended way to hook custom access control logic
 - Filters

 ## 1.1 ApiResource

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

