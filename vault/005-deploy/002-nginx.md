### Using _NGINX_ Web Server

_This tutorial assumes that you already have some knowledge on _NGINX_ and _Server Block_ files._  If you're not acquainted with NGINX or want to know more about it, visit the [NGINX Official Docs](http://nginx.org/en/docs/beginners_guide.html#conf_structure).

---

 To configure Nginx to serve a SPLIT PHP application you need to:
1. create a new _Server Block_ file inside the _sites-available_ Nginx's directory
2. insert the code shown bellow, making the necessary adaptations, into this file
3. save it and then enable it on Nginx

```php
server {
  listen 80;
  listen [::]:80 ipv6only=on;

  server_name example.com.br;

  root /path/to/your/app/root/public;
  index index.php;

  location / {
    try_files $uri $uri/ /index.php?$query_string;
    fastcgi_param QUERY_STRING $query_string;
  }

  location /resources {
    try_files $uri $uri/ =404;
  }

  location ~ \.php$ {
    try_files $uri /index.php =404;
    # This line below is a default path to PHP in linux systems. If your PHP is installed in another location, change it to your actual fpm path.
    fastcgi_pass unix:/var/run/php/php7.2-fpm.sock;
    fastcgi_index index.php;
    fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    include fastcgi_params;
  }
  location ~ \.git {
    deny all;
  }
}
```

 Here we have some points of attention:
1. **The `server_name` option:** you must set this option with your application's domain name.
2. **The `root` option:** you must set this option with the absolute path to your application's public directory.
3. **The `fastcgi_pass` option, inside `location ~ \.php$` section:** this option indicates the _PHP fpm_ path inside your server. If you have an UNIX based OS installed on it, you **probably** won't have to change it. But if your server's _PHP fpm_ is located elsewhere you will have to set the absolute path to it in here.

 Now you just have to enable the newly created site's _Server Block_ config file, and restart the NGINX web server.   OBS This configuration is not prepared to serve sites under SSL certificates (HTTPS). In order to make this, you will have to provide additional settings. Learn more about it following this [link](http://nginx.org/en/docs/http/configuring_https_servers.html).

---
