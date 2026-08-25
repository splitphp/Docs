### Exceptions

 SplitPHP has its own exception hierarchy, designed to distinguish errors that should become a **client-friendly HTTP response for the API consumer** from internal/technical errors. There is no mention of this in the official documentation.

---

##### `UserException` — the base for "business" errors

 `SplitPHP\Exceptions\UserException` is an **abstract** class that extends `Exception`. It exists for errors the **API client is supposed to see** (validation, permission, resource not found, etc.) — unlike a regular `Exception`, which is treated as an internal/unexpected error.

```php
<?php
$exc->getStatusCode();     // int|null — the associated HTTP code (e.g. 404)
$exc->getStatusMessage();  // string|null — the associated HTTP message (e.g. "Not Found")
$exc->isUserReadable();    // bool — whether the message can be shown to the end user
```

 The framework ships with 7 ready-made subclasses, one for each common situation, each pre-configured with a default HTTP code and message (but customizable via the constructor):

| Class | Default code | Default message |
| --- | --- | --- |
| `BadRequest` | 400 | "Bad Request" |
| `Unauthorized` | 401 | "Unauthorized" |
| `Forbidden` | 403 | "Forbidden" |
| `NotFound` | 404 | "Not Found" |
| `MethodNotAllowed` | 405 | "Method Not Allowed" |
| `Conflict` | 409 | "Conflict" |
| `FailedValidation` | 422 | "Failed Validation" |

```php
<?php
namespace YourApp\Services;

use SplitPHP\Service;
use SplitPHP\Exceptions\UserExceptions\NotFound;

class Animals extends Service {
  public function findOne($id){
    $animal = $this->getDao('Animal')->filter('id_animal')->equalsTo($id)->first();

    if(empty($animal)) throw new NotFound("Animal #{$id} does not exist.");

    return $animal;
  }
}
```

 They all accept the same 4 constructor parameters: `string $message`, `int $code` (overrides the default), `bool $usrReadable` (default `true`) and `?Throwable $previous`.

  NOTE Throwing one of these exceptions inside a `WebService` endpoint is the idiomatic way to return a specific HTTP error to the client, without having to manually build `$this->response->withStatus(...)`.

---

##### `DatabaseException`

 Thrown internally by the framework when a database operation fails, wrapping the original driver exception:

```php
<?php
$exc->getSqlState();  // the SQLSTATE returned by the database
$exc->getSqlCmd();    // the SQL command that caused the error
```

 Useful in `catch` blocks to log/debug query failures along with the exact command that caused them.

---

##### `EventException`

 Thrown when an **event listener** (see [[001-events|Events System]]) throws any exception during its execution — the `EventDispatcher` catches it and wraps it in this class, so that a listener's error doesn't take down the main operation without a trace:

```php
<?php
$exc->getEvent();             // ?Event — the event that was being processed
$exc->getOriginalException();  // Throwable — the original exception thrown by the listener
```

---

##### `ExceptionHandler`

 Central class that handles any uncaught exception in the framework: `SplitPHP\ExceptionHandler::handle(Throwable $exception, ?Request $request = null, ?Execution $execution = null)`. It:

1. Rolls back the current database transaction, if `DB_CONNECT` and `DB_TRANSACTIONAL` are enabled.
2. Prints the exception to the console (CLI context) and writes a log entry, if logging is enabled.
3. Returns the original exception (or a new one, depending on the case).

 You normally don't call this directly — it's the internal mechanism that handles any error not caught by your code.

---

##### Related Links

- See [[001-events|Events System]] for the event dispatch cycle and `EventException`.
- See [[001-database-and-connections|Database & Connections]] for `DatabaseException` in the context of DAO operations.

---
