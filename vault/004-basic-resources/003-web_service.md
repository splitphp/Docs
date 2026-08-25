### Web Service

 The _WebService_ is your API layer, the gatekeeper of your application.

---

##### How to create a _WebService_

 Web Services are classes, which extend the `SplitPHP\WebService` main class, inheriting, though, all it's mechanics. Your application's web services, are gonna be located under _"/application/routes"_.

 So, answering the question "How do I create a WebService in my app?": it's just a matter of creating a class, which extends `SplitPHP\WebService` class, and save it in a file under the directory _"/application/routes"_.
##### _WebService_, Son of _Service_

 The _WebService_ extends _Service_, though inheriting all of its methods.

All the routes registration occurs at _runtime_, using an imperative paradigm, instead of using a static, config-like mechanic.

This has several advantages but one trade-off. The main advantage is the fact that everything about an endpoint is dynamic, so you could, for instance, write some condition to wether or not add some endpoints or even change dynamically their very routes. This is robust, but comes with a trade-off: you can't just register them in the class as functions, variables or constants as they will be added _on-the-flight_. So, they must be called from within a method.

Here's where the special method _init()_ comes in hand. You can add all your endpoints inside the _init()_ and they will be automatically added as soon as the _WebService_ class finishes its construction. See examples in the next section.
##### Routes and the URL

 An application exposes its resources by the use of _endpoints_, which are basically routes, on which a function is executed, when accessed.

To register endpoints under your _WebService_, you make use of the _addEndpoint()_ built-in method:

```php
<?php
namespace YourAppName\Routes;

use SplitPHP\WebService;

class MyApi extends WebService{
  public function init(){
    $this->addEndpoint('GET', '/hello', function(){
      return $this->response
        ->withStatus(200)
        ->withText("Hello from endpoint '/hello'");
    });

    $this->addEndpoint('GET', '/foo', function(){
      return $this->response
        ->withStatus(200)
        ->withText("Hello from endpoint '/foo'");
    });

    $this->addEndpoint('GET', '/bar', function(){
      return $this->response
        ->withStatus(200)
        ->withText("Hello from endpoint '/bar'");
    });
  }
}
```

   NOTE Be aware that the endpoints are being added from within _init()_.
##### The anatomy of an endpoint

 The UX of this is similar to Node's "Express.JS". An endpoint have 3 main parts basically:
- **The HTTP verb:** which consists in the Verb(s) accepted by the endpoint. The allowed values are:
  - `GET`
  - `POST`
  - `PUT`
  - `DELETE`

- **The route:** it is the URL listened by the endpoint. The address that will be accessed by the client.
- **The callback function:** it is the function that will be called when the endpoint is triggered.
 So, when a client access the URL registered in _route_, using the HTTP Verb registered in _Verb_, it will run the function registered in the _callback function_. Pretty straightforward, isn't it?

**But if I need to retrieve data from the _request_?**

You can just pass, to the _callbak function_, a parameter of type `SplitPHP\Request`:

```php
<?php
namespace YourAppName\Routes;

use SplitPHP\WebService;
use SplitPHP\Request; // <== SplitPHP\Request class type

class MyApi extends WebService{
  public function init(){
    $this->addEndpoint('GET', '/hello/?name?', function(Request $req){
      $name = $req->getRoute()->params['name'];
      return $this->response->withStatus(200)->withText("Hello, {$name}! Welcome to SplitPHP Framework.");
    });

    $this->addEndpoint(['POST','PUT'], '/save-something', function(Request $req){
      $formData = $req->getBody();
      $newSomething = $this->getService('foo/bar')->save($formData);

      return $this->response
      ->withStatus(201)->withData($newSomething);
    });

    $this->addEndpoint(['POST','PUT'], '/other/?someParam?', function($params){
      $someParam = $params['someParam'];
      unset($params['someParam']);

      $reqBody = $params;

      $this->getService('foo/bar')->doSomething($someParam, $reqBody);

      return $this->response
        ->withStatus(204);
    });
  }
}
```

   NOTE The route params are placed in the _route_ between 2 question marks (?paramName?).   NOTE The 3rd endpoint callback doesn't receive a Request object, instead, it will be given a merge of the body with the route params.
##### The _Response_ object

 All endpoints must always return a _Response_ object and the _WebService_ already initializes and stores it in `$this->response` property.

This object is used to control the API's response informations as: status code, content type, headers and body. This response is formed using the _builder pattern_, with subsequent callings of Response object's methods:

```php
<?php
...
$this->response
  ->setHeader("Some-Header: Value")
  ->withStatus(200)
  ->withHTML($htmlContentString);
```

The _withStatus()_ method set the http status code that will be returned to the client in the response. This can be any integer.

The _setHeader()_ method receives a qualified header-string and set it to the response.

Furthermore, we have the methods which defines the content format of the data that will be sent in the body of the response. Currently we have the following options:
- `withText(string $text, bool $escape = true)`: sets response's content type to "text/plain" and attach the content of `$text` in the response body with no formatting.
- `withData($data, bool $escape = true)`: sets response's content type to "application/json", encodes the content of `$data` into JSON and then attach it to the response body.
- `withHTML(string $content)`: sets response's content type to "text/html" and attach the content of `$content` to the response body with no formatting.
- `withXMLData($data)`: sets response's content type to "application/xml", encodes the content of `$content` to XML and then attach it to the response body.
- `withCSS($content)`: sets response's content type to "text/css", then attachs the content of `$content` to the response body with no formatting.

To give a full example, let's imagine that we're building a RESTful API with a CRUD for the entity "Animal":

```php
<?php
namespace App\Routes;

use SplitPHP\WebService;
use SplitPHP\Request; // <== SplitPHP\Request class type

class Animals extends WebService{
  public function init(){
    // Get one:
    $this->addEndpoint('GET', '/v1/animal/?id?', function(Request $req){
      $id = $req->getRoute()->params['id'];
      $data = $this->getService('animals')->findOne($id);

      return $this->response
        ->withStatus(200)
        ->withData($data); // <= JSON response
    });

    // List:
    $this->addEndpoint('GET', '/v1/animal', function(Request $req){
      $filters = $req->getBody()
      $data = $this->getService('animals')->list($filters);

      return $this->response
        ->withStatus(200)
        ->withData($data); // <= JSON response
    });

    // Create
    $this->addEndpoint('POST', '/v1/animal', function(Request $req){
      $formData = $req->getBody();
      $newAnimal = $this->getService('animals')->create($formData);

      return $this->response
        ->withStatus(201)
        ->withData($newSomething);
    });

    // Update
    $this->addEndpoint('PUT', '/v1/animal/?id?', function(Request $req){
      $id = $req->getRoute()->params['id'];
      $formData = $req->getBody();

      $affectedRows = $this->getService('animals')->upd($id, $formData);

      // Responds 404 (not found) if no record is updated:
      if($affectedRows < 1) return $this->response->withStatus(404);

      return $this->response
        ->withStatus(204);
    });

    // Delete:
    $this->addEndpoint('DELETE', '/v1/animal/?id?', function(Request $req){
      $id = $req->getRoute()->params['id'];

      $affectedRows = $this->getService('animals')->remove($id);

      // Responds 404 (not found) if no record is deleted:
      if($affectedRows < 1) return $this->response->withStatus(404);

      return $this->response
        ->withStatus(204);
    });
  }
}
```

---
