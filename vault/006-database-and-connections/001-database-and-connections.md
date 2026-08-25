### Database & Connections

 This section documents the database connection layer (`SplitPHP\Database\Database`, `DbCredentials`, `DbVocab`) and a set of **DAO** methods that are not covered in the basic [[004-dao|DAO]] tutorial. It complements, rather than replaces, that section.

---

##### The `Database` class

 `SplitPHP\Database\Database` is the static connection manager — the one the **DAO** uses under the hood to get the active connection. You rarely need to call it directly (the DAO already takes care of that), but it comes in handy when a service needs to switch databases/credentials at runtime (e.g. multi-tenant systems).

```php
<?php
use SplitPHP\Database\Database;
use SplitPHP\Database\DbCredentials;

// Gets (or creates) a named connection:
$cnn = Database::getCnn('main', new DbCredentials('localhost', 'user', 'pass', 3306));

// Swaps the credentials of an existing connection:
Database::changeCnn('main', new DbCredentials('otherhost', 'user2', 'pass2'));

// Checks whether a named connection already exists:
if (Database::checkCnn('main')) { /* ... */ }

// Removes and closes a connection:
Database::removeCnn('main');

// Sets/gets the database name used globally:
Database::setName('my_database');
$dbName = Database::getName();

// Sets/gets the RDBMS name used globally (e.g. 'mysql'):
Database::setRdbmsName('mysql');
$rdbms = Database::getRdbmsName();
```

- `getCnn(string $cnnName, ?DbCredentials $credentials = null)`: returns the connection instance (`DbCnn`) named `$cnnName`. If it doesn't exist yet, creates it using `$credentials`.
- `removeCnn(string $cnnName)`: closes and removes the connection. Returns `bool`.
- `changeCnn(string $cnnName, ?DbCredentials $credentials = null)`: swaps the credentials of an existing connection.
- `checkCnn(string $cnnName)`: returns a `bool` indicating whether the connection exists.
- `setName(string $name)` / `getName()`: name of the database used by default.
- `setRdbmsName(string $name)` / `getRdbmsName()`: name of the RDBMS used by default (currently only a MySQL driver ships built-in, in `core/database/mysql/`).

  NOTE The framework uses **two named connections by convention**: `'main'` (read/write) and `'readonly'` (used by the DAO for read operations, via `find()`). This allows you, for example, to point `readonly` at a replica.

---

##### `DbCredentials`

 An immutable value object that bundles a connection's host, user, password and port:

```php
<?php
use SplitPHP\Database\DbCredentials;

$cred = new DbCredentials('localhost', 'root', 'pass123', 3306); // port is optional

$cred->getHost();   // 'localhost'
$cred->getUser();   // 'root'
$cred->getPass();   // 'pass123'
$cred->getPort();   // 3306
$cred->export();    // associative array with the 4 fields, ready to pass along
```

---

##### `DbVocab` and `SqlExpression`

 `DbVocab` is a dictionary of constants used in *migrations* and blueprints (e.g. `DbVocab::FKACTION_CASCADE`, `DbVocab::IDX_UNIQUE`, `DbVocab::DATATYPE_INT` — already used in the [[005-migrations|Migrations]] examples). The only relevant method on the class is:

- `DbVocab::SQL_CURTIMESTAMP()`: returns a `SqlExpression` (not a string) representing `CURRENT_TIMESTAMP` in the generated SQL — that's how `setDefaultValue(DbVocab::SQL_CURTIMESTAMP())` works without turning into an escaped `'CURRENT_TIMESTAMP'` string literal.

 `SqlExpression` is a simple wrapper around a raw SQL expression (`get()` returns the text, `equals($other)` compares), used internally to tell "literal value" apart from "SQL expression" — you normally don't instantiate it directly.

---

##### Stored Procedures in Migrations

 Besides `Table()`, a *Migration* can also declare **procedures** via `ProcedureBlueprint` (class `SplitPHP\DbManager\Blueprints\ProcedureBlueprint`), something not mentioned in the [[005-migrations|Migrations]] tutorial:

```php
<?php
namespace YourApp\Migrations;

use SplitPHP\DbManager\Migration;

class CreateCalcTotalProcedure extends Migration {
  public function apply(){
    $this->Procedure('calc_total')
      ->withArg('id_order', 'INT')
      ->outputs('total', 'DECIMAL(10,2)')
      ->setInstructions("SELECT SUM(price) INTO total FROM order_items WHERE id_order = id_order;");
  }
}
```

- `withArg(string $name, string $type)`: adds an input argument.
- `outputs(string $name, string $type)`: defines the procedure's output parameter.
- `setInstructions(string $instructions)`: the procedure's SQL body.
- `drop()`: (inherited from `Blueprint`) marks the procedure to be dropped instead of created.

  NOTE Just like `Table()`, calling `$this->Procedure('name')` again in a future migration **alters** the existing procedure (it gets recreated with the new definition).

 Once created, a procedure becomes accessible directly through the **DAO**, via a "magic method" mechanism: any call to a DAO method whose name matches an existing procedure in the database invokes it automatically, with no extra declaration needed:

```php
<?php
// Calls the "calc_total" stored procedure, passing id_order as an argument:
$dao = $this->getDao()->calc_total(['id_order' => 42]);

// Retrieves the result (set by reference):
$dao->outputProcResult($result);
```

---

##### DAO — advanced methods (not covered in the basic tutorial)

 The [[004-dao|DAO]] tutorial covers `filter()`, the comparison operators, `and()`/`or()`, `find()`/`first()`/`fetch()` and `insert()`/`update()`/`delete()`. The methods below exist on the same class and are not documented anywhere else:

- **`bindParams(array $params, ?string $placeholder = null)`**: an alternative to `filter()` for parameterizing a raw SQL query (passed to `find()`), replacing `?name?` placeholders directly in the SQL text instead of building `WHERE` clauses. Useful when the query already has conditional logic too complex for the filter builder.

  ```php
  <?php
  $results = $this->getDao('PEOPLE')
    ->bindParams(['minAge' => 18])
    ->find("SELECT * FROM PEOPLE WHERE age >= ?minAge?");
  ```

- **`getFilters()`**: returns the array of filters accumulated so far in the current operation (useful for debugging or for composing more complex queries).
- **`static dbCommitChanges()`**: forces a manual commit of the current transaction (when `DB_TRANSACTIONAL` is on) and immediately opens a new one — for long-running operations that need to "save" partial checkpoints.
- **`static clearPersistence()`**: clears the `SELECT` result cache the DAO keeps internally (the DAO caches the result of a given query within the same execution, to avoid re-querying).
- **`static flush()`**: shortcut that calls `dbCommitChanges()` followed by `clearPersistence()`.
- **`insert()`/`update()`/`delete()` with `$debug = true`**: any of these operations, when called with the second parameter (or only parameter, in the case of `delete`) set to `true`, does **not** execute the operation — it returns the `Sqlobj` object with the SQL that would have run, useful for debugging without touching the database.

---

##### Related Links

- See [[004-dao|DAO]] for basic DAO usage.
- See [[005-migrations|Migrations]] for `Table()`, columns, indexes and foreign keys.
- See [[006-seeds|Seeds]] for using `Seed()` inside a `Table` (test data).

---
