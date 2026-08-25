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

##### Related Links

- See [[004-dao|DAO]] for Data Access usage.
- See [[005-migrations|Migrations]] for `Table()`, columns, indexes, foreign keys and Stored Procedures.
- See [[006-seeds|Seeds]] for using `Seed()` inside a `Table` (test data).

---
