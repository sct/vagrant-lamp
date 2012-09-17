# Vagrant LAMP

A configurable LAMP development stack for Vagrant.

## Installation

Install [vagrant](http://vagrantup.com/)

    $ gem install vagrant

Download and Install [VirtualBox](http://www.virtualbox.org/)

Clone this repository

Go to the repository folder and launch the box

    $ cd [repo]
    $ vagrant up

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

Apache virtual hosts are created in `sites` folder and configured in your Vagranthost file.

The vagrant machine is set to use IP 33.33.33.10 by default. To use your own domains such as local.dev, you need to add them to your hosts file. If you just go to http://33.33.33.10/ in a browser, you will the first of your defined sites (alphabetical order).

Webgrind and phpMyAdmin are available on every domain. For example:

* http://local.dev/phpmyadmin
* http://local.dev/webgrind

PHP is configured to send mail via MailCatcher. Web frontend of MailCatcher is running on port 1080 and also available on every domain:

* http://local.dev:1080

Port 33066 is forwarded to MySql, with a default vagrant/vagrant user so you can use your favorite client to administer databases.


## Sites configuration

These site configuration settings should be put into your personal Vagranthost.rb, so that you don't accidentially commit passwords or other sensitive data to git. Have a look at Vagranthost.template.rb, change some settings and save it as Vagranthost.rb to use them.

Whenever you need to apply new configurations all you need to do is run the provisioning again.

    $ vagrant provision

If that does not work, you might have to destroy your virtual machine and recreate it. Beware that this will destroy any data saved on the server such as databases and other configurations not present in these scripts.

    $ vagrant destroy
    $ vagrant up


### Standard site

```ruby
"sites" => [
	{ 
		# Used for ServerName and document root (sites/local.dev)
		:host => "local.dev", 

		# Used for ServerAlias
		:aliases => ["example.dev","foo.dev"], 


		# The following are not required, but useful

		# Tells apache to use sites/local.dev/webroot as DocumentRoot.
		:webroot => "webroot", 

		# This triggers some special features for Magento (clear cache, setup cron, etc)
		:framework => "magento", 
	}
]
```

### Site with database

```ruby
{
	:host => "database.dev",
	:aliases => [],
	:database => "my_db",
	:db_user => "my_db",
	:db_pass => "my_db",
}
```

### Automatically import database from file

```ruby
{
	:host => "import.dev",
	:aliases => [],
	:database => "my_import",
	:db_user => "my_import",
	:db_pass => "my_import",
	:db_import_file => "import.sql" # File needs to exist in (sites/import.dev)
}
```

### Automatically sync database from remote server
Database will be dumped on remote, copied over and imported.

```
{
	:host => "sync.dev",
	:webroot => "webroot",
	:aliases => [],
	:framework => "magento",
	:database => "my_sync",
	:db_user => "my_sync",
	:db_pass => "my_sync",
	:db_sync => { # All fields below are required
		:ssh_host => "sync.example.com",
		:ssh_user => "vagrant",
		:ssh_private_key => "vagrant_id_rsa", # This file must exist in vagrant root.
		:mysql_user => "root",
		:mysql_pass => "password",
		:remote_database => "my_sync"
	}
}
```

## Supported frameworks

The provisioning script has support for some automated setup of frameworks and CMS.

### Magento
- Clears cache on startup/provision (deletes all files in /var/cache).
- Creates a cron file for running Magento cron (/etc/cron.d/magento).
- After a database sync, it sets the base_url in the database to site host.

