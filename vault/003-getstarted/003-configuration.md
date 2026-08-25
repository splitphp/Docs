### Configuration

 _ In SPLIT PHP there are several options and settings, which are static information, that are available in the entire system and they're used to do many different things. _

---

Firstly, in the root folder of your project, run: `php console setup`

 Then it will appear a file named **_.env_**. In this file you can **set up your application** to do stuff like establish connection to a specific database, define what to show as the first page of your system and so on. In summary: it is used to **configure the app**.

---

##### The Available Options

 Here you'll find a detailed explanation of what is each option and how to set it up:

[PHP Supported Timezones](https://www.php.net/manual/en/timezones.php)

| Option | Value | Description | Default |
| --- | --- | --- | --- |
| DB_CONNECT | "on"/  "off" | If set to "on", tries to connect to a database and throws an exception if the connection fails. If you haven't a database associated with the application, keep it "off". | "off" |
| DBHOST | A string containing the URL to the database's host. | This option indicates the address of the host where the database is located. | "localhost" |
| DBNAME | A string containing the name of the database. | This option indicates what is the name of the database of the application, inside that host. | None |
| DBPORT | An integer containing the port at which database is available for connection. | This option indicates what is the port of the database of the application, inside that host. | 3306 |
| DBUSER | A string containing the user's username of the database. | This user is used to perform all operations in the database, except read operations. This option is this user's username credential. | None |
| DBPASS | A string containing This user's password of the database. | This user is used to perform all operations in the database, except read operations. This option is this user's password credential. | None |
| DB_CHARSET | A string containing the charset used on the database. | Define here the default charset. | utf8 |
| RDBMS* | "mysql"/  "mariadb"/  "postgresql"/  "sqllite"/  "sqlserver"/  "oracle" | Indicates the type of the database. | "mysql" |
| DB_TRANSACTIONAL | "on"/  "off" | All write operations in the database are executed, by default, within transactions. This allows the system to automatically undo (rollback) these operations if something wrong happens and the application throws an exception during runtime. This assures the consistence of the data in the base. If, for some specific reason, you don't want these behavior, you can turn it off setting this option to "off". Otherwise, keep it "on". | "on" |
| DB_WORK_AROUND_FACTOR | An integer value | When an attempt to connect or to execute an operation in the database fails, the system tries to redo it again. This option indicates how many times the system shall retry it before give up and throws an exception. | 5 |
| CACHE_DB_METADATA | "on"/  "off" | When performing operations in database, the system does some mapping on the entities and stores it as metadata. This options indicates whether or not these metadata should be cached in-file. | "on" |
| APPLICATION_NAME | A string containing the name of the application. | The name of the application, that will be available in the entire system to whatever purpose. | None |
| DEFAULT_ROUTE | A string with the default route. (Example: "/home/hello") | This options indicates what route shall be executed when an end-user accesses the root URL. (Example: http://www.my-site.com/) | /site/home |
| DEFAULT_TIMEZONE | A timezone formatted string. | This option sets the timezone of the entire system to one of the PHP's supported timezone strings. () | None |
| HANDLE_ERROR_TYPES | PHP constants. | This tells to PHP what kinds of errors and warnings it shall capture and handle. Do not change the defaults unless you know exactly what you're doing. | E_ALL & ~E_NOTICE & ~E_USER_NOTICE |
| APPLICATION_LOG | "on"/  "off" | This indicates to the system whether or not it should save logs of the errors and exceptions at the application level. | "on" |
| PRIVATE_KEY | A string containing a hash. | This hash is generated automatically by php console setup and represents a key which can be used to identify the application or to perform encryption/decryption operations. | None |
| PUBLIC_KEY | A string containing a hash. | This hash is generated automatically by php console setup and represents a key which can be used to identify the application or to perform encryption/decryption operations. | None |
| ALLOW_CORS | "on"/"off" | Wheither allow CORS requests or not. | on |
| MAX_LOG_ENTRIES | An integer value | An integer that defines how many log entries the system is allowed to store at the same time in a single log file. | 5 |
| MAINAPP_PATH | A string containing, the path to the application source directory. | It is in this directory that all your services, WebServices and etc. will lie. | /application |
| MODULES_PATH | A string containing, the path to the modules source directory. | It is in this directory that all your preset modules and plug-ins will lie. | /modules |
| APP_ENV | A string containing, the name of the current environment. | This can be used to control some environment-bound behaviors. | development |

 NOTE ** The `RDBMS` option currently supports only _MySQL_ databases. So if you set any other value than `"mysql"` on this option, it won't work properly. The support to the other relational databases described, will be implemented in future releases. **

---
