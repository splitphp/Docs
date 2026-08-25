### Database Seeds

 Just like [[005-migrations|Migrations]] version the database **structure**, **Seeds** version **data** — test data, reference data (e.g. a list of countries), or any record that needs to exist in a predictable, repeatable way in any environment. This feature exists in the framework but **is not documented in any section of the official website**.

---

##### How to create a Seed

 Just like with migrations, generate the boilerplate through the console:

```php
php console generate:seed
```

 This creates a file in `{MAINAPP_PATH}/dbseeds/`, with a numbered (timestamped) name, following the same ordering logic as migrations:

```php
<?php
namespace YourApp\Seeds;

use SplitPHP\DbManager\Seed;

class YourSeedName extends Seed {
  public function apply(){
    // Define the seed for a table, with 10 records per batch:
    $this->SeedTable('Person', 10)
      ->onField('name')->setRandomStr(5, 30)
      ->onField('dt_birth')->setRandomDate('1970-01-01', '2005-12-31')
      ->onField('id_company')->setFromOperation(-1); // uses the id inserted in the previous operation
  }
}
```

---

##### The anatomy of a Seed

- **`$this->SeedTable(string $tableName, int $batchSize = 1)`**: starts the data definition for the table `$tableName`, inserting `$batchSize` records per batch. Returns a `SeedBlueprint`.
- **`$this->onDatabase(string $dbName)`**: (optional) specifies which database the seed should run on, when the project works with multiple databases.

###### ➤ Defining the value of each field (`SeedBlueprint` methods, chainable after `onField()`):

- `->onField(string $field, bool $tagAsIndex = false)`: selects the field to be configured next. `$tagAsIndex = true` marks that field as the record's identifier (useful for referencing it later via `setFromOperation`).
- `->setFixedValue(mixed $value)`: fixed value, the same in every record of the batch.
- `->setRandomStr($minlength = 0, $maxlength = 255)`: random string.
- `->setRandomInt($min = 0, $max = PHP_INT_MAX)`: random integer.
- `->setRandomFloat($min = 0, $max = PHP_FLOAT_MAX)`: random float.
- `->setRandomDate($start = '2000-01-01', $end = '2100-12-31')`: random date within the range.
- `->setRandomDateTime($start = '...', $end = '...')`: random date and time within the range.
- `->setRandomEnum(array $values)`: picks a random value from the ones passed in `$values`.
- `->setByFunction(callable $function)`: value computed by a custom function (called once per record).
- `->setFromOperation(int $opIndexOffset, ?string $fieldName = null, ?int $insertedRecordIndex = null)`: uses the ID (or another field) of a record inserted by a **previous** operation within the same seed. `$opIndexOffset` is negative (e.g. `-1` = the immediately previous operation) — essential for populating foreign keys between related seeds.

###### ➤ Environment control:

- `->onlyRunInEnvs(array $envs)`: restricts the seed to run only in the listed environments (e.g. `['development', 'staging']`, never in production). Throws an exception if any item is not a string.
- `->isAllowedInEnv(string $env)`: programmatically checks whether the seed is allowed in the given environment.

  NOTE This environment control is what prevents test data from "leaking" into production when applying seeds — it's always worth using in seeds that generate fake data.

---

##### Seed coupled to a Migration (`CoupledSeedBlueprint`)

 Besides the Seed as a separate class, you can populate data **inside the migration itself**, by chaining `->Seed()` after defining a `Table`:

```php
<?php
$this->Table('Country')
  ->id('id_country')
  ->string('name', 100)
  ->Seed(5) // 5 records per batch
    ->onField('name')->setFixedValue('Brasil');
```

 This variant (`CoupledSeedBlueprint`) supports the same methods from `onField()` onward listed above (except `setFromOperation`, which only exists in the standalone Seed).

---

##### Running and managing Seeds

```php
php console seeds:apply       # applies all pending seeds
php console seeds:rollback    # reverts the applied seeds
php console seeds:status      # lists seeds and their status ("pending" / "applied")
php console seeds:help        # detailed help
```

  NOTE Just like with migrations, you don't need to write the rollback logic manually — the framework reverts the `INSERT`s automatically.

---

##### Related Links

- See [[005-migrations|Migrations]] for table/column definitions.
- See [[001-database-and-connections|Database & Connections]] for database connector helpers.

---
