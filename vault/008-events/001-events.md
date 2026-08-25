### Events System

 SplitPHP has a built-in events system (publish/subscribe) that runs internally at several points of the framework's lifecycle, and which can also be extended with **the application's own events and listeners**. None of this is documented on the official website.

---

##### Listening to events that already exist in the framework

 To react to an event, create a class in `{MAINAPP_PATH}/eventlisteners/`, extending `SplitPHP\EventListener`:

```php
<?php
namespace YourApp\EventListeners;

use SplitPHP\EventListener;

class MyListeners extends EventListener {
  protected function init(){
    $this->addEventListener('log.error', function($evt){
      // $evt is the corresponding Event instance (e.g. LogError)
      // ... send a notification, store it somewhere else, etc.
    });

    $this->addEventListener('response.before', function($evt){
      // runs right before any HTTP response is sent
    });
  }
}
```

- `protected function init()`: abstract method that every listener class must implement — this is where you register the listeners.
- `$this->addEventListener(string $evtName, callable $callback)`: registers `$callback` to run when the `$evtName` event fires. Returns a unique ID (string) that can be used to remove the listener later.
- `EventListener::removeEventListener($evtId)` (static): removes a specific listener by its ID.
- `EventListener::eventRemoveListeners($evtName)` (static): removes all listeners of an event.
- `EventListener::getListeners()` (static): lists all currently registered listeners.

 Inside the callback, calling `$evt->stopPropagation()` interrupts the chain of remaining listeners for that event (by default propagation continues — `shouldPropagate()` is `true`).

---

##### Catalog of core built-in events

 These are the events the framework itself fires (each one is a class in `core/events/`, all with the `info()` method, which returns formatted details of the event):

| Event (`evtName`) | Class | When it fires | Available data |
| --- | --- | --- | --- |
| `command.before` | `CommandBefore` | Before executing a CLI command | `getExecution()`-like info via `info()` |
| `curl.before` | `CurlBefore` | Before a request made by the `Curl` helper | `getDatetime()`, `getUrl()`, `getHttpVerb()`, `getHeaders()`, `getRawData()`, `getPayload()` |
| `curl.response` | `CurlResponse` | After a `Curl` helper request returns successfully | same as `curl.before` + `getOutput()` |
| `curl.error` | `CurlError` | When a `Curl` helper request fails | same as `curl.before` + `getOutput()`, `getErrorMsg()` |
| `log.common` | `LogCommon` | Every time `Helpers::Log()->common()`/`add()` writes a log | `getLogName()`, `getLogMsg()`, `getLogFilePath()`, `getLogFileName()`, `getLogFileFullPath()` |
| `log.error` | `LogError` | Every time `Helpers::Log()->error()` writes an error log | same as `log.common` + `getException()` |
| `request.before` | `BeforeRequest` | Before processing the incoming HTTP request | access to the `Request` object |
| `response.before` | `BeforeResponse` | Immediately before sending the HTTP response | access to the `Response` object (by reference — you can modify the response) |
| `response.after` | `AfterResponse` | Immediately after sending the HTTP response | access to the `Response` object |

  NOTE `response.before`/`response.after` are particularly useful for centralized logging of all API responses, without having to repeat code in every `WebService`.

---

##### Creating the application's own events

 Besides listening to core events, you can create and fire custom events. A custom event is a class in `{MAINAPP_PATH}/events/`, extending `SplitPHP\Event`:

```php
<?php
namespace YourApp\Events;

use SplitPHP\Event;

class OrderPlaced extends Event {
  const EVENT_NAME = 'order.placed'; // required - this is the name used in addEventListener()

  private $orderId;

  public function __construct($orderId){
    $this->orderId = $orderId;
  }

  public function getOrderId(){
    return $this->orderId;
  }

  public function info(){
    return "Order #{$this->orderId} was placed.";
  }
}
```

- Every event class **must** declare the public constant `EVENT_NAME` — this is how the `EventDispatcher` discovers and indexes the event; without it, the framework throws an exception when mapping the events.
- The `info()` method is abstract and mandatory (used for logging/debugging the event).

 To fire the event, use `EventDispatcher::dispatch()`:

```php
<?php
use SplitPHP\EventDispatcher;
use YourApp\Events\OrderPlaced;

EventDispatcher::dispatch(function() {
  // the "real" action the event involves (e.g. actually saving the order)
}, OrderPlaced::EVENT_NAME, [$orderId]);
```

 `dispatch(callable $dispatcherFn, string $evtName, array $data = [])`: executes `$dispatcherFn` (the main action) **and** notifies all listeners registered for `$evtName`, passing `$data` as the event's constructor arguments. If any listener calls `stopPropagation()`, `$dispatcherFn` **is not executed**.

  NOTE If `DB_CONNECT` and `DB_TRANSACTIONAL` are enabled, the listener dispatch runs inside its own transaction — an error in a listener does not corrupt the main operation (it is caught and handled via `EventException` + `ExceptionHandler`).

---

##### Folder convention (via `map.ini`)

 The events/listeners folders (and the application's other folders) follow a convention, configurable in `{MAINAPP_PATH}/map.ini`:

| `map.ini` key | Default folder | Contents |
| --- | --- | --- |
| `EVENTS_BASEPATH` | `events` | The application's custom events |
| `EVENTLISTENERS_BASEPATH` | `eventlisteners` | Listener classes |
| `ROUTES_BASEPATH` | `routes` | WebServices |
| `SERVICES_BASEPATH` | `services` | Services |
| `TEMPLATES_BASEPATH` | `templates` | Templates |
| `COMMANDS_BASEPATH` | `commands` | Custom CLI commands |
| `SQL_BASEPATH` | `sql` | External `.sql` files used by `find()` |
| `DBMIGRATION_BASEPATH` | `dbmigrations` | Migrations |
| `DBSEEDS_BASEPATH` | `dbseeds` | Seeds |

 This table applies both to the main application (`AppLoader`) and to modules (`ModLoader`) — see [[001-cli-and-generators|CLI & Generators]] for more on the command structure.

---

##### Related Links

- See [[001-exceptions|Exceptions]] for the handling of errors thrown inside a listener (`EventException`).
- See [[001-helpers|Helpers]] for the `Curl` helper, whose calls fire the `curl.*` events.

---
