### Database Migrations

 This resource serves the purpose of managing the structure of the database, providing a way to version it.

---

##### How to setup a Database _Migration_

 As everything else in the system, _Migrations_ are classes. The only special thing about them is that its names/filenames must follow a specific pattern, so the system can control the order of each _Migration_. To facilitate this, **Split PHP** has a built-in command to generate the migrations, already with its name and with a boilerplate, ready for you to set it up:

```php
php console generate:migration
```

 This will ask you some questions, then, create a new file at the location specified at "`MAINAPP_PATH`/dbmigrations/", with the following structure:

```php
<?php
namespace YourApp\Migrations;

use SplitPHP\DbManager\Migration;
use SplitPHP\Database\DbVocab;

class YourMigrationName extends Migration{
  public function apply(){
    /**
     * Here goes your migration's statements. For example, the following code
     * creates or alters a table called 'Person', and adds or changes this
     * table's columns: 'id_person', 'id_company' 'name' and 'dt_birth':
     *
     * $this->Table('Person')
     *  ->id('id_person') // int primary key auto increment
     *  ->int('id_company') // int
     *  ->Foreign('id_company')->references('id_company')->atTable('Company')->onUpdate(DbVocab::FKACTION_CASCADE)
     *  ->string('name', 100) // varchar(100)
     *  ->datetime('dt_birth') datetime
     *    ->setDefaultValue(DbVocab::SQL_CURTIMESTAMP()); // default current timestamp
     */
  }
}
```

  OBS More information about the `MAINAPP_PATH` settings, visit the [[003-configuration|Configuration Section]] in this documentation.

 The syntax is declarative and very straightforward: you start an operation by invoking `$this->Table('TABLE_NAME')` and, using the _building pattern_, you start declaring the columns, indexes and foreign keys. Here are the available options:
###### ➤ Column-defining Options:

- `->id(string $columnName)`: defines an integer-type column, named `$columnName`, with _auto increment_, then sets it as the table's _Primary Key_
- `->int(string $columnName)`: defines an integer-type column, named `$columnName`
- `->string(string $columnName, int $length)`: defines a varchar-type column, named `$columnName`, with length: `$length`.
- `->text(string $columnName)`: defines a text-type column, named `$columnName`.
- `->bigInt(string $columnName)`: defines a bigint-type column, named `$columnName`.
- `->decimal(string $columnNam)`: defines a decimal-type column, named `$columnName`.
- `->float(string $columnName)`: defines a float-type column, named `$columnName`.
- `->date(string $columnName)`: defines a date-type column, named `$columnName`.
- `->datetime(string $columnName)`: defines a datetime-type column, named `$columnName`.
- `->time(string $columnName)`: defines a time-type column, named `$columnName`.
- `->timestamp(string $columnName)`: defines a timestamp-type column, named `$columnName`.
- `->boolean(string $columnName)`: defines a boolean-type column, named `$columnName`.
- `->blob(string $columnName)`: defines a blob-type column, named `$columnName`, to store binary file content.
- `->json(string $columnName)`: defines a json-type column, named `$columnName`, to store JSON-formatted data.
- `->uuid(string $columnName)`: defines a uuid-type column, named `$columnName`, unique string IDs.

###### ➤ The Anatomy of an Index:

 The indexes are defined by a couple idiomatic chained functions:
- `->Index(string $name, string $type)`: start the indexe's definition by setting its name and type.
- `->onColumn(string $columnName)`: sets a single column on which the index will be attached.
- `->setColumns(array $columns)`: sets multiple columns on which the index will be attached.

 The whole definition of an index would look like this:

```php
<?php
      ...
      $this->Table('TABLE_NAME')
      ...
      ->Index('INDEX_NAME', 'INDEX_TYPE')->onColumn('COLUMN_NAME');

```

###### ➤ The Anatomy of a Foreign key:

 The FKs are defined by chaining some functions in an idiomatic way:
- `->Foreign(string|array $columns)`: start the Fk's definition by attaching it to one or multiple columns.
- `->references(string $columnName)`: sets the column of the referenced table.
- `->atTable(string $tableName)`: sets name of the referenced table.
- `->onUpdate(string $action)`: defines the Fk's behavior on update events.(Ex.: `CASCADE`)
- `->onDelete(string $action)`: defines the Fk's behavior on delete events.(Ex.: `RESTRICT`)

 The whole definition of a foreign key would look like this:

```php
<?php
      ...
      $this->Table('TABLE_NAME')
      ...
      ->Foreign('COLUMN_NAME')
      ->references('REF_COLUMN_NAME')
      ->atTable('REF_TABLE_NAME')
      ->onUpdate(DbVocab::FKACTION_CASCADE)
      ->onDelete(DbVocab::FKACTION_RESTRICT);

```

###### ➤ Extra options:

 And here are the other controls and options necessary to manage your database structure:
- `->drop()`: sets the previous definition (Table, Column, Index or FK), to be dropped.
- `->nullable()`: applicable only to columns, tells the system that the column to be created/updated must accept **null** value.
- `->unsigned()`: applicable only to int/bigint-type columns, sets the column as `UNSIGNED`.
- `->setDefaultValue($val)`: applicable only to columns, sets the default value for the column.

###### ➤ How does a whole migration looks like:

```php
<?php
namespace YourApp\Migrations;

use SplitPHP\DbManager\Migration;
use SplitPHP\Database\DbVocab;

class YourMigrationName extends Migration{
  public function apply(){

    /**
     * Creates or updates a table named 'Person' with the following setup:
     */
    $this->Table('Person')
     ->id('id_person') // int primary key auto increment
     ->string('u_key' 60) // unique key varchar(60)
     ->string('name', 100) // varchar(100)
     ->int('id_company') // int
     ->date('dt_birth')->nullable()->setDefaultValue(null) // nullable date
     ->datetime('created_at')->setDefaultValue(DbVocab::SQL_CURTIMESTAMP()) // datetime which defaults to current date and time
     ->Index('U_KEY', DbVocab:IDX_UNIQUE)->onColumn('u_key')
     ->Foreign('id_company')->references('id_company')->atTable('Company')->onUpdate(DbVocab::FKACTION_CASCADE)->onDelete(DbVocab::FKACTION_RESTRICT)
  }
}
```

###### ➤ Dropping a column which was set in a previous _Migration_:

 Imagine that, some time after running the _Migration_ above, you need to replace the column _'dt_birth'_ by _'age'_:

```php
<?php
namespace YourApp\Migrations;

use SplitPHP\DbManager\Migration;
use SplitPHP\Database\DbVocab;

class YourNextMigrationName extends Migration{
  public function apply(){

    /**
     * Updates the table 'Person' with the following setup:
     */
    $this->Table('Person')
     ->date('dt_birth')->drop() // drops the previously-defined column 'dt_birth'
     ->int('age')->nullable->setDefaultValue(null); // sets a new nullable, integer column 'age'
  }
}
```

---

##### Running and managing your _Migrations_

###### ➤ Running my _Migrations_:

 The command bellow applies all the pending migrations:

```php
php console migrations:apply
```

###### ➤ Rolling-back my _Migrations_:

 The command bellow rolls back all the applied migrations:

```php
php console migrations:rollback
```

  NOTE You don't need to explicitly define the rollback behavior(the "down" function) of the _Migrations_, the framework is smart enough to guess it by itself.
###### ➤ Checking my Database Status:

 The command bellow shows a list of all the migrations and their statuses("pending" or "applied") and other information:

```php
php console migrations:status
```

  NOTE For more information about the specific migrations options, run the command:

```php
php console migrations:help
```

##### Stored Procedures
Besides `Table()`, a *Migration* can also declare **procedures** via `ProcedureBlueprint` (class `SplitPHP\DbManager\Blueprints\ProcedureBlueprint`):
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

> **NOTE:** Just like `Table()`, calling `$this->Procedure('name')` again in a future migration **alters** the existing procedure (it gets recreated with the new definition).

 Once created, a procedure becomes accessible directly through the **DAO**, via a "magic method" mechanism: any call to a DAO method whose name matches an existing procedure in the database invokes it automatically, with no extra declaration needed:

```php
<?php
// Calls the "calc_total" stored procedure, passing id_order as an argument:
$dao = $this->getDao()->calc_total(['id_order' => 42]);

// Retrieves the result (set by reference):
$dao->outputProcResult($result);
```
