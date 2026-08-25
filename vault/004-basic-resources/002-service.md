### Service

 A _Service_ is an independent piece of functionality, which is available all over the system. The keyword here is "reusability".

---

##### What is a _Service_?

 A _Service_ is basically a class, that you can name in any way you want, which extends the main class `SplitPHP\Service`, inheriting all its mechanics, and located at _"/application/services"_ folder.

 It's in the services that the _magic_ happens. All database operations, business rules, requirements, etc. goes in the services. We can say that the ensemble of the services, is the system itself. So, basically what you got is a system that is formed by an ensemble of classes. Simple enough?!
##### Let me show you an example of a Service:

 Imagine that you're building a Service which performs basic arithmetic operations.
- Firstly, you create the _Service_ itself:

```php
<?php
// this class is located in a file called "arithmetic.php" inside the folder "/application/services".

namespace YourAppName\Services;

use SplitPHP\Service; // this is the main class that this service will inherit from.

class Arithmetic extends Service{

}
```

- Now, let's add the _sum_ functionality of our Arithmetic's Service:

```php
<?php
// This class is located in a file called "arithmetic.php" inside the folder "/application/services".

namespace YourAppName\Services;

use SplitPHP\Service; // this is the main class that this service will inherit from.

class Arithmetic extends Service{
  public function sum($value1, $value2){
    return $value1 + $value2;
  }

}
```

- If you get the idea, let's add _subtraction_, _multiplication_ and _division_ operations in our service:

```php
<?php
// This class is located in a file called "arithmetic.php" inside the folder "/application/services".

namespace YourAppName\Services;

use SplitPHP\Service; // this is the main class that this service will inherit from.

class Arithmetic extends Service{
  public function sum($value1, $value2){
    return $value1 + $value2;
  }

  public function subtraction($value1, $value2){
    return $value1 - $value2;
  }

  public function multiplication($value1, $value2){
    return $value1 * $value2;
  }

  public function division($value1, $value2){
    return $value1 / $value2;
  }
}
```

##### Ok, done! But how can you access these functionalities from outside this _Service_?

 Inside any service you have the `$this->getService()` method available. This method is used to invoke and instantiate any other service. So, from a service, you can invoke another service by using `$this->getService()` builtin method.

 The `$this->getService()` method requires the service's path as a parameter - this path starting from the _"/application/services"_ folder - to identify which service it will return and the returned value is an object of the service's class itself. This allows you to call service's operations using [builder design pattern](https://www.mitrais.com/news-updates/implementing-builder-pattern-in-php-programming-design-pattern-solution/), directly, without having to instantiate the service's object explicitly:

```php
<?php
...
$this->getService('path/to/the/service')->serviceMethod();
...
```

##### Here's an example:

 Imagine, now, that in your system you have a "_Salesorder_" service which has an _applyDiscount_ operation, which uses the operations defined in that _Arithmetic's service_, that we created before, to calculate the discounts of a sales order. In order to do it, it will make use of `$this->getService()` method:

```php
<?php
namespace YourAppName\service;

use SplitPHP\Service;

class Salesorder extends Service{
  public function applyDiscount($orderValue, $discountValue){
    $finalValue = $this->getService('arithmetic')->subtraction($orderValue, $discountValue);

    return $finalValue;
  }
}

```

   OBS You can find more detailed information about the method `$this->getService()` in the session Reference Guide of this documentation.   NOTE It's in the service that the interface to operate the database is available, by using the SPLIT PHP's DAO (Data Access Object). Learn more about it visiting the session [[004-dao|Components -> DAO]] of this documentation.
##### What's more in it?

 Ok, so now we know that a service is just a class stored in _"/application/services"_ folder, which extends the `SplitPHP\Service` framework's class, we can make any initializing using _init()_ special method and, also, that we can, from any service, access any method of any other service, using the builtin method `$this->getService()`. But what more can a service do?

 The answer is: manage _Templates_!

 A template is a PHP file, which contains HTML (or any other markup language that you want) and it must be located in _"/application/templates"_. The service does so by using another builtin method called `$this->renderTemplate()`. This method receives a template's path as the first parameter - this path starting from _"/application/templates"_ folder - and returns a string of the contents of this template, which you can use to render as page in the browser or use as a message's body in an email, for instance:
-  The template located at **_"/application/templates/hello.php"_**:

```html
<h1>Hello World from a template!</h1>
```

-  The service that manages it:

```php
<?php
namespace YourAppName\Services;

use SplitPHP\Service;

class Servicename extends Service{
  public function printTemplateHello(){
    $tplContent = $this->renderTemplate('hello'); // the variable $tplContent holds a string with the content "<h1>Hello World from a template!</h1>"

    echo $tplContent; // prints out the HTML recovered from the template.
  }
}
```

 You can also pass, as the second parameter, a **var list**, with dynamic content, to this template, so it can render it's value inside the HTML content:
-  The template located at **_"/application/templates/hello.php"_**:

```php
<h1>Hello <?php echo $name; ?>!</h1>
```

-  In the service:

```php
<?php
namespace YourAppName\Services;

use SplitPHP\Service;

class Servicename extends Service{
  public function printTemplateHello(){
    $tplContent = $this->renderTemplate('hello', ['name' => "Gandalf"]); // the variable $tplContent holds a string with the content "<h1>Hello Gandalf!</h1>"

    echo $tplContent; // prints out the HTML recovered from the template.
  }
}
```

  NOTE The name of the variable in the template is the same key of the **var list** array, passed as the second parameter to `$this->renderTemplate()` in the service.   OBS You can learn more about the **templates** in the session [[002-service|Components -> Template]] of this documentation.   OBS You can find more detailed information about the method `$this->renderTemplate()` in the session Reference Guide of this documentation.

---

##### Wrapping up!

-  A service is a class, located at _"/application/services"_ folder, that manages a single part of the system (Ex.: User service, which manages application's users).
-  If you need to automatically run anything at the initialization of the _Service_ you are able to it by making use of the special method _init()_.
-  It is available to any other service in the application by the use of `$this->getService()` method, but it's not directly available to the client.
-  All logics, rules and operations of the system will be performed by services.
-  The `$this->getService()` method exposes a [builder design pattern](https://www.mitrais.com/news-updates/implementing-builder-pattern-in-php-programming-design-pattern-solution/) interface, so you can call the service's method right after `$this->getService()`, without having to instantiate the service's class object explicitly.
-  It's in the service that you will operate your application's database, using the interface of [[004-dao|DAO]].
-  You can manage your application's templates by the use of `$this->renderTemplate()` method.

 That's it! In the next section you will learn about the _Web Service_ and how you connect your services to the requests of the client. See you there!

---
