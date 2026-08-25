### Helpers

 SplitPHP ships with a handful of utility classes ("helpers"), accessible from anywhere via the static facade `SplitPHP\Helpers`. None of them are documented on the official site.

```php
<?php
use SplitPHP\Helpers;

Helpers::Log();       // SplitPHP\Helpers\Log
Helpers::cURL();      // SplitPHP\Helpers\Curl
Helpers::MemUsage();  // SplitPHP\Helpers\MemUsage
Helpers::DbMapper();  // SplitPHP\Helpers\DbMapper
Helpers::Stash();     // SplitPHP\Helpers\Stash
Helpers::Spawn();     // SplitPHP\Helpers\Spawn
Helpers::SSE();       // SplitPHP\Helpers\SseStream (always a NEW instance, never cached)
```

---

##### `Curl` — HTTP client

```php
<?php
$result = Helpers::cURL()
  ->setHeader('Authorization: Bearer xyz')
  ->setDataAsJson(['foo' => 'bar'])
  ->post('https://api.example.com/resource');
```

- `setHeader(string $header)`, `setUserAgent(string $userAgent)`: configure the request (chainable).
- `setData($data)` / `setDataAsJson($data)`: request body (raw or as JSON).
- `get($url)`, `post($url)`, `put($url)`, `patch($url)`, `del($url)`: per-verb shortcuts.
- `request($httpVerb, $url)`: generic form.

 Each call fires the `curl.before` event, followed by `curl.response` (success) or `curl.error` (failure) — see [[001-events|Events System]].

---

##### `Log` — file logging

```php
<?php
Helpers::Log()->common('my-routine', "Process started.");
Helpers::Log()->error('my-routine', $exception, ['context' => 'extra']);
```

- `common(string $logname, $logmsg, $limit = true)` (alias: `add()`): writes `$logmsg` with a timestamp to `ROOT_PATH/log/{$logname}`. `$limit` controls whether the file gets rotation/size limiting.
- `error(string $logname, Throwable $exc, array $info = [])`: writes a formatted log entry from an exception, with optional extra info.
- `exceptionBuildLog(Throwable $exc, array $info)`: builds the log object from the exception (used internally by `error()`, but exposed in case you want to compose the log manually).

 Each write fires the `log.common`/`log.error` events — you can plug in a listener and, for instance, forward critical errors to an external channel without touching every log call scattered across the codebase.

---

##### `MemUsage` — memory instrumentation

```php
<?php
Helpers::MemUsage()->logMemory('after-processing', 256 * 1024 * 1024);
```

- `logMemory(string $label, int $abortIfOver = 128*1024*1024)`: records the current memory usage under the label `$label`; if it exceeds `$abortIfOver` bytes, execution is aborted (a safeguard against memory leaks in long-running routines/loops).

---

##### `Spawn` — parallelism via process forking

 Lets you run a block of code in an **isolated child process**, with the entire SplitPHP environment (connections, loaders, event cache) re-initialized from scratch — useful for parallelizing heavy work without inheriting state from the parent process.

```php
<?php
Helpers::Spawn()->async()->run(function(){
  // runs in a separate child process, in parallel
  $this->getService('reports')->generateHeavy();
});
Helpers::Spawn()->wait(); // blocks until the async children finish
```

- `async(bool $async = true)`: if `true` (the default when called with no argument), `run()` returns immediately and the child runs in the background; combine with `wait()` afterwards.
- `detach()`: "fire-and-forget" mode — the parent process never waits for nor cares about the child (SIGCHLD ignored, no zombies). Incompatible with `wait()`.
- `run(callable $fn)`: performs the fork and runs `$fn` in the child. In synchronous mode (the default without `async()`), the parent blocks until the child finishes.
- `wait()`: blocks until all of the instance's async (non-detached) children finish.

  NOTE Only available in environments with `pcntl` support (typically CLI/worker, not inside the request cycle of a traditional web server).

---

##### `SseStream` — Server-Sent Events

 Helper for opening an SSE connection (long-lived server-to-browser events), used inside a `WebService` endpoint:

```php
<?php
$this->addEndpoint('GET', '/events', function(){
  $stream = Helpers::SSE()->ttl(300)->tickInterval(500)->open();

  $stream->tick(function($stream){
    $stream->emit('heartbeat', ['time' => time()]);
    return true; // keep going; returning false ends the loop
  });

  $stream->close();
});
```

- `ttl(int $seconds)`: maximum connection lifetime before emitting `reconnect` and closing.
- `tickInterval(int $ms)`: interval between iterations of the main loop.
- `reconnectDelay(int $ms)`: the `retry:` value sent to the browser (how long to wait before reconnecting).
- `open()`: sends the SSE headers and releases PHP's session lock (essential — without it, other requests from the same session get stuck behind the long-lived connection).
- `emit(string $eventType, array $payload = [])`: sends an event frame (JSON-encoded automatically).
- `tick(callable $tickFn)`: runs the main loop, calling `$tickFn($stream)` on each iteration until the `ttl` expires, the client disconnects, or `$tickFn` returns `false`.
- `close()`: shuts the connection down gracefully, emitting a `reconnect` event.

  NOTE Each call to `Helpers::SSE()` returns a **new** instance (never cached) — every SSE connection needs its own lifecycle.

---

##### `Stash` — simple key-value store (JSON)

```php
<?php
Helpers::Stash()->set('last_sync', date('c'));
$value = Helpers::Stash()->get('last_sync', $default = null);
Helpers::Stash()->delete('last_sync');
$all = Helpers::Stash()->getAll();
```

 Stores key-value pairs in a local JSON file (in the application's cache folder) — handy for simple state that doesn't justify a database table (e.g. control timestamps, flags).

- `setStashFilePath(string $path)`: customizes the file used (relative to the cache folder), in case you don't want to use the shared default.

---

##### `DbMapper` — existing-schema introspection

```php
<?php
$blueprint = Helpers::DbMapper()->tableBlueprint('Person'); // TableBlueprint with the CURRENT state of the table
$procBlueprint = Helpers::DbMapper()->procedureBlueprint('calc_total');
```

- `tableBlueprint(string $tableName)`: returns a `TableBlueprint` representing the **current** state of the table in the database (existing columns, indexes, FKs) — useful for assisted migration generation or for programmatic schema introspection.
- `procedureBlueprint(string $procName)`: same thing, for an existing stored procedure.

---

##### Related Links

- See [[001-events|Events System]] for the events fired by `Curl` and `Log`.
- See [[001-database-and-connections|Database & Connections]] for `ProcedureBlueprint`, used by `DbMapper::procedureBlueprint()`.

---
