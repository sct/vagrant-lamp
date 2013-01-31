# Vagrant LAMP

Configurable LAMP development stack for Vagrant.

## Installation

1. Install vagrant from [vagrantup.com](http://vagrantup.com/)
2. Download and Install VirtualBox from [virtualbox.org](http://www.virtualbox.org/)
3. Clone this repository to a folder of your choice (I have it in my home folder)
5. Add this row to your local machine's "hosts" file (Linux/Mac: "/etc/hosts")<br>

    ```33.33.33.10 vagrant.dev```

6. Go to the repository folder and launch the box
  
  ```
  $ cd [repo]
  $ vagrant up
  ```
7. Wait for vagrant to download, start and provision your virtual machine (a few minutes)
8. When the setup is done you can visit your local development host at http://vagrant.dev/
9. Any files you add to the folder sites/vagrant.dev/ will be visible at http://vagrant.dev/
10. Now you can configure your own sites, see the onfiguration section below.

## What's inside

Installed software:

* Apache
* MySQL
* php
* phpMyAdmin
* Xdebug with Webgrind
* zsh with [oh-my-zsh](https://github.com/robbyrussell/oh-my-zsh)
* git, subversion
* mc, vim, screen, tmux, curl
* [MailCatcher](http://mailcatcher.me/)

The vagrant machine is set to use IP 33.33.33.10 by default.

Webgrind and phpMyAdmin are available on every domain. For example:

* http://vagrant.dev/phpmyadmin
* http://vagrant.dev/webgrind

PHP is configured to send mail via MailCatcher. Web frontend of MailCatcher is running on port 1080 and also available on every domain:

* http://vagrant.dev:1080

Port 33066 is forwarded to MySql, with a default vagrant/vagrant user so you can use your favorite client to administer databases.

You can add XDEBUG\_PROFILE to your GET parameter to generate an xdebug trace, e.g. http://vagrant.dev/?XDEBUG\_PROFILE. You can then investigate at http://local.dev/webgrind/


## Sites configuration

Site configurations are stored as json files in the folder databag/site. These configs automatically set up apache virtual hosts and databases. They can also import databases and rsync uploaded files from a remote server. See examples below.

Whenever you need to apply new configurations all you need to do is run the provisioning again.

    $ vagrant provision

Put your code for the site in the "sites" folder, within a folder named as the "host" in your config.

Also remember to add your new site hosts to your local machine's hosts file.

    33.33.33.10 vagrant.dev project.dev project2.dev


### Standard site

Put your web app in the folder ```sites/local.dev/``` for this site configuration to work.

```json
{
	"id": "local",
	"host": "local.dev", // Used for ServerName and document root (sites/local.dev)
	"aliases": [ "example.dev", "foo.dev" ]
}
```

### Site with database

Put your web app in the folder ```sites/database.dev/``` for this site configuration to work.

```json
{
	"id": "database",
	"host": "database.dev",
	"database": [{
		"db_name": "my_db",
		"db_user": "my_db",
		"db_pass": "my_db",
	}]
}
```

### Automatically import database from file

Put your web app in the folder ```sites/import.dev/```. You also need a database dump named ```sites/import.dev/import.sql``` for this config to work.

```json
{
	"id": "import",
	"host": "import.dev",
	"database": [{
		"db_name": "my_import",
		"db_user": "my_import",
		"db_pass": "my_import",
		"db_import_file": "import.sql" // File needs to exist in (sites/import.dev)
	}]
}
```

### Automatically copy database from remote server

For this config to work you need an SSH account on a remote server and a MySQL account. For the SSH account you must have Public Key Authentication set up and your private key file needs to exist in the root vagrant directory.

I use a single private key file without a passphrase for all the servers I need to sync databases and files from. This is a separate private key from the one I usually use, since it has no passphrase it is best to use it only for syncing from development and testing servers.

Read more about public and private keys at [help.ubuntu.com](https://help.ubuntu.com/community/SSH/OpenSSH/Keys).

```json
{
	"id": "copy",
	"host": "copy.dev",
	"webroot": "webroot", // Tells apache to use sites/local.dev/webroot as DocumentRoot.
	"framework": "magento", // Triggers special features for Magento (clear cache, cronjob). 
	"database": [{
		"db_name": "my_copy",
		"db_user": "my_copy",
		"db_pass": "my_copy",
		"db_copy": { // All fields below are required
			"ssh_host": "sync.example.com",
			"ssh_user": "vagrant",
			"ssh_private_key": "vagrant_id_rsa", // This file must exist in vagrant root.
			"mysql_user": "root",
			"mysql_pass": "password",
			"remote_database": "my_copy"
		}
	}]
}
```

## Supported frameworks

The provisioning script has support for some automated setup of frameworks and CMS.

### Magento
- Clears cache on startup/provision (deletes all files in /var/cache).
- Creates a cron file for running Magento cron (/etc/cron.d/magento).
- After a database sync, it sets the base_url to site host.

### Drupal
- Clears cache on startup/provision using drush.

### Wordpress
- After a database sync, it sets the home and siteurl to site host.
