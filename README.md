# Vagrant LAMP

Configurable LAMP development stack for Vagrant.

## Installation

1. Install vagrant from [vagrantup.com](http://vagrantup.com/)
2. Download and Install VirtualBox from [virtualbox.org](http://www.virtualbox.org/)
3. Clone this repository to a folder of your choice (I have it in my home folder)
4. (Optional) Duplicate Vagranthost.template.rb to Vagranthost.rb and configure your sites.
5. Setup your hosts file with the domains you need

	```33.33.33.10 local.dev project.dev project2.dev```
	
6. Go to the repository folder and launch the box
  
  ```
  $ cd [repo]
  $ vagrant up
  ```

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

The vagrant machine is set to use IP 33.33.33.10 by default. To use your own domains such as local.dev, you need to add this line to your /etc/hosts (or windows equivalent).

    33.33.33.10 local.dev project.dev project2.dev

Webgrind and phpMyAdmin are available on every domain. For example:

* http://local.dev/phpmyadmin
* http://local.dev/webgrind

PHP is configured to send mail via MailCatcher. Web frontend of MailCatcher is running on port 1080 and also available on every domain:

* http://local.dev:1080

Port 33066 is forwarded to MySql, with a default vagrant/vagrant user so you can use your favorite client to administer databases.

You can add XDEBUG_PROFILE to your GET parameter to generate an xdebug trace, e.g. http://local.dev/?XDEBUG_PROFILE. You can then investigate at http://local.dev/webgrind/


## Sites configuration

These site configuration settings should be put into your personal Vagranthost.rb, so that you don't accidentially commit passwords or other sensitive data to git. Have a look at Vagranthost.template.rb, change some settings and save it as Vagranthost.rb to use them.

Whenever you need to apply new configurations all you need to do is run the provisioning again.

    $ vagrant provision

If that does not work, you might have to destroy your virtual machine and recreate it. Beware that this will destroy any data saved on the server such as databases and other configurations not present in these scripts.

    $ vagrant destroy
    $ vagrant up


### Standard site

Put your web app in the folder sites/local.dev for this site configuration to work.

```ruby
"sites" => [
	{ 
		:host => "local.dev", # Used for ServerName and document root (sites/local.dev)
		:aliases => ["example.dev","foo.dev"],
	}
]
```

### Site with database

```ruby
{
	:host => "database.dev",
	:aliases => [],
	:database => [{
		:db_name => "my_db",
		:db_user => "my_db",
		:db_pass => "my_db",
	}]
}
```

### Automatically import database from file

```ruby
{
	:host => "import.dev",
	:aliases => [],
	:database => [{
		:db_name => "my_import",
		:db_user => "my_import",
		:db_pass => "my_import",
		:db_import_file => "import.sql" # File needs to exist in (sites/import.dev)
	}]
}
```

### Automatically copy database from remote server
Database will be dumped on remote, copied over and imported.

```ruby
{
	:host => "copy.dev",
	:aliases => [],
	:webroot => "webroot", # Tells apache to use sites/local.dev/webroot as DocumentRoot.
	:framework => "magento", # Triggers special features for Magento (clear cache, cronjob). 
	:database => [{
		:db_name => "my_copy",
		:db_user => "my_copy",
		:db_pass => "my_copy",
		:db_copy => { # All fields below are required
			:ssh_host => "sync.example.com",
			:ssh_user => "vagrant",
			:ssh_private_key => "vagrant_id_rsa", # This file must exist in vagrant root.
			:mysql_user => "root",
			:mysql_pass => "password",
			:remote_database => "my_copy"
		}
	}]
}
```

## Supported frameworks

The provisioning script has support for some automated setup of frameworks and CMS.

### Magento
- Clears cache on startup/provision (deletes all files in /var/cache).
- Creates a cron file for running Magento cron (/etc/cron.d/magento).
- After a database sync, it sets the base_url in the database to site host.

