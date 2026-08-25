### Request, Response (Advanced) and Utils

 Complements the [[003-web_service|Web Service]] tutorials, covering `Request` methods not mentioned there, the `WebService` security features (XSRF) and the `Utils` utility class.

---

##### `Request` — methods beyond `getRoute()`/`getBody()`

 The Web Service tutorial already shows `$req->getRoute()->params` and `$req->getBody()`. The `Request` object (`SplitPHP\Request`) has more to offer:

- `getVerb()`: returns the request's HTTP verb (`'GET'`, `'POST'`, etc.).
- `getBody(?string $key = null)`: without an argument, returns the whole body; with `$key`, returns only that field.
- `setBody(string $key, mixed $value)` / `unsetBody(string $key)`: modifies the already-parsed request body (useful in `request.before` listeners, to normalize data before it reaches the endpoint).
- `getHeader(?string $headerName = null)`: without an argument, returns all headers; with `$headerName`, only that header's value.
- `getWebService()`: returns the `WebService` instance handling the request.
- `static setContext(string $key, mixed $value)` / `static getContext(string $key)`: a **static key-value store**, valid for the entire request — a way to pass data between layers (e.g. from an event listener to a service) without having to chain parameters.

  ```php
  <?php
  // In a 'request.before' listener:
  Request::setContext('tenant_id', $resolvedTenantId);

  // Later, in any service:
  $tenantId = Request::getContext('tenant_id');
  ```

- `static getUserIP()`: returns the client's IP (also used internally to generate the XSRF token, see below).

---

##### XSRF security in `WebService`

 The Web Service tutorial doesn't mention that **every request, by default, requires a valid XSRF token**. This is controlled by extra, undocumented parameters of `addEndpoint()`:

```php
<?php
// addEndpoint(string|array $httpVerb, string $route, $method, ?bool $antiXsrf = null, bool $antiXSS = true)

$this->addEndpoint('POST', '/webhook/terceiro', function(Request $req){
  // public webhook endpoint, without requiring XSRF:
}, antiXsrf: false);
```

- **4th parameter (`$antiXsrf`)**: if `false`, turns off the XSRF token requirement **for that endpoint only** (useful for public third-party webhooks, which obviously have no way to send the token). If `null` (default), it uses the `WebService`'s global setting.
- **5th parameter (`$antiXSS`)**: if `false`, turns off the automatic XSS sanitization on the data received by that endpoint.
- `$this->setAntiXsrfValidation(bool $validate)` (inside `init()`): turns the XSRF requirement on/off for **all** endpoints of that `WebService` at once.
- `$this->xsrfToken()`: returns the XSRF token generated for the current session/IP (sent to the client in the `Xsrf-Token` header of every response) — the client must send it back in subsequent requests (`Xsrf-Token` header or `xsrf_token` field in the body/query).
- `$this->set404template(string $path, array $args = [])` (inside `init()`): defines a custom template (see [[002-service|Templates]]) to be rendered when no route matches, instead of the default bodyless 404.

  NOTE The XSRF token is derived from the client's IP (`Request::getUserIP()`), encrypted with the `PRIVATE_KEY` from the configuration — it's not a server session, so it works statelessly.

---

##### `Utils` — general static utilities

 `SplitPHP\Utils` is a class of miscellaneous helper functions, available globally, and **extensible**: you can register custom methods on it.

```php
<?php
use SplitPHP\Utils;

Utils::escapeHTML($formData);                        // sanitizes against XSS (recursive on arrays/objects)
Utils::isJson($string);                              // bool
Utils::stringToSlug("Título com Acentuação!");        // "titulo_com_acentuacao"
Utils::stringToPascalCase("meu-nome-de-classe");      // "MeuNomeDeClasse"
Utils::regexTest('/^\d+$/', $value);                  // boolean wrapper around preg_match
Utils::dataEncrypt($data, $key);                      // reversible encryption
Utils::dataDecrypt($hash, $key);                      // reverses dataEncrypt()
Utils::convertToUTF8($content);                       // normalizes encoding
Utils::XML_encode($data, 'nodes', 'node');            // array/object -> XML string
Utils::filterData($filterRules, $data);               // removes regex patterns from $data
Utils::validateData($validationRules, $data);         // validates $data against regex patterns (throws an exception)
Utils::preg_grep_keys('/^campo_/', $assocArray);      // filters an associative array by its KEYS via regex
```

- **`registerMethod(string $methodName, callable $instructions)`**: registers a **custom** static method on `Utils`, callable afterwards as `Utils::yourMethod(...)` — an extension mechanism for the application's own utility functions, without having to create a new class.

  ```php
  <?php
  Utils::registerMethod('formatarMoeda', function($valor){
    return 'R$ ' . number_format($valor, 2, ',', '.');
  });

  // Anywhere in the code, afterwards:
  Utils::formatarMoeda(1234.5); // "R$ 1.234,50"
  ```

- `lineBreak()`: returns `\n` or `<br>`, depending on whether the context is CLI or Web.
- `printLn($data = "")`: prints `$data` followed by a line break (respecting `lineBreak()`).
- `pad($text, $length)`, `buildSeparator($columnWidths)`, `cliTable(iterable $items, ?array $columns = null)`: utilities for formatting table output in the terminal (used by the framework's own CLI commands, e.g. `migrations:status`).

---

##### Related Links

- See [[003-web_service|Web Service]] for the basic usage of `addEndpoint()` and `Response`.
- See [[001-events|Events System]] for the `request.before` event, where `Request::setContext()` is typically used.

---
