### CLI (`php console`) — Built-in Commands and Custom Commands

 The [[005-migrations|Migrations]] tutorial mentions `php console migrations:*` and the [[004-running|Running]] one mentions `php console server:*`, but the **console itself** — all the built-in commands and how to create your own — isn't documented anywhere.

---

##### Built-in commands, by CLI

| CLI | Commands | What it does |
| --- | --- | --- |
| `help` | `php console help` | Lists all available CLIs and commands |
| `invoke` | `php console invoke:...` | Manually invokes a service/method (debug utility) |
| `migrations` | `apply`, `rollback`, `status`, `help` | See [[005-migrations|Migrations]] |
| `seeds` | `apply`, `rollback`, `status`, `help` | See [[001-seeds|Seeds]] |
| `server` | `start`, `stop`, `status`, `help` | Starts/stops the built-in PHP server (dev) — see [[004-running|Running]] |
| `setup` | `php console setup:...` | Initial project setup |
| `generate:cli` | `php console generate:cli` | Generates boilerplate for a custom CLI |
| `generate:migration` | `php console generate:migration` | Generates boilerplate for a migration (see [[005-migrations|Migrations]]) |
| `generate:seed` | `php console generate:seed` | Generates boilerplate for a seed (see [[001-seeds|Seeds]]) |
| `generate:service` | `php console generate:service` | Generates boilerplate for a Service |
| `generate:webservice` | `php console generate:webservice` | Generates boilerplate for a WebService |

  NOTE Every command accepts `:help` (e.g. `php console seeds:help`) to list the options specific to that CLI.

---

##### Creating your own CLI command

 A custom CLI is a class in `{MAINAPP_PATH}/commands/` (configurable via `map.ini`, key `COMMANDS_BASEPATH` — see [[001-events|Events System]] for the full folder-convention table), extending `SplitPHP\Cli`:

```php
<?php
namespace YourApp\Commands;

use SplitPHP\Cli;
use SplitPHP\Execution;

class Relatorios extends Cli {
  public function init(){
    $this->addCommand('gerar', function(Execution $exec){
      $this->getService('relatorios')->gerarMensal();
      echo "Report generated successfully!" . PHP_EOL;
    });
  }
}
```

 Runnable afterwards as: `php console relatorios:gerar`.

- `public abstract function init()`: where commands are registered (called automatically on construction, same pattern as `WebService::init()`).
- `protected final function addCommand(string $cmdString, $method)`: registers `$cmdString` (the text after `:`) associated with `$method` (a callable or a method name on the class itself).
- `protected final function run(string $cmdString)`: executes another command from within a command (command composition).
- `static supportsAnsi()`: indicates whether the current terminal supports ANSI colors (used to conditionally colorize output).
- `execute(Execution $execution)`: internal method that dispatches to the right handler — not usually called directly.

---

##### Distribution folder structure

 For reference, the structure of a fresh install (`console`, `application/`, `core/`, `public/`) — the only folder the developer edits day to day is `application/` (mapped by `map.ini`, see the table in [[001-events|Events System]]); everything in `core/` belongs to the framework:

```
/
├── console                  # CLI entrypoint (php console ...)
├── application/             # YOUR code
│   ├── routes/               # WebServices
│   ├── services/              # Services
│   ├── templates/             # Templates
│   ├── commands/               # Custom CLIs (optional)
│   ├── events/                  # Custom events (optional)
│   ├── eventlisteners/           # Listeners (optional)
│   ├── sql/                       # External SQL (optional)
│   ├── dbmigrations/               # Migrations
│   └── dbseeds/                     # Seeds
├── core/                    # the framework itself (do not edit)
├── modules/                 # pluggable modules (same structure as application/, with its own ModLoader)
└── public/                  # web server document root (index.php)
```

  NOTE The `modules/` folder exists to split parts of the system into independent modules, each with its own tree of routes/services/migrations — same loading mechanism as `application/`, but via `ModLoader` instead of `AppLoader`. This isn't documented on the official site either.

---

##### Related Links

- See [[005-migrations|Migrations]] and [[006-seeds|Seeds]] for the database-specific commands.
- See [[001-events|Events System]] for the full folder-convention table (`map.ini`).

---
