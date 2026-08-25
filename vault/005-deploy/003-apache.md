### Using _Apache 2_ Web Server

_This tutorial assumes that you already have some knowledge on _Apache 2_ and its _Virual Hosts_._  If you're not acquainted with Apache 2 or want to know more about it, visit the [Apache's Official Docs](https://httpd.apache.org/docs/2.4/).

---

 To configure Apache to serve a SPLIT PHP application you need to:
1. create a new _Virual Host_ file inside the _sites-available_ Apache's directory
2. insert the code shown bellow, making the necessary adaptations, into this file
3. save it and then enable it on Apache

```php
<VirtualHost *:80>
    ServerAdmin your.email@site-domain
    ServerName site-domain.com
    ServerAlias www.site-domain.com
    DocumentRoot /path/to/application/root/public
    CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
```

 Here we have some points of attention:
1. **The `ServerAdmin` option:** you must set this option with a proper email, where the site's administrator can receive messages.
2. **The `ServerName` option:** you must set this option with your application's domain name.
3. **The `ServerAlias` option:** you must set this option with your application's domain name preceding by "www.".
4. **The `DocumentRoot` option:** you must set this option with the absolute path to your application's public directory.

 Now you just have to enable the newly created site's _Virtual Host_ config file, and restart the Apache web server.

 It is possible that the Apache's **`mod_rewrite`** module isn't activated, then you will run into some problems with URL. In order to activate it manually run this command:

```php
a2enmod rewrite
```

 ***: This command can vary a little bit depending on your OS.**   OBS This configuration is not prepared to serve sites under SSL certificates (HTTPS). In order to make this, you will have to provide additional settings. Learn more about it following this [link](https://httpd.apache.org/docs/2.4/ssl/).

---
