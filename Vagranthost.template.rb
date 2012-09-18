# -*- mode: ruby -*-
# vi: set ft=ruby :

# If you copy this file to Vagranthost.rb
# it will not be version controlled so 
# you can use it to store your personal configs


# Run any extra vagrant config you need
def hostconfig(config)

	# Give the virtual machine more memory and "dual core cpu"
	config.vm.customize ["modifyvm", :id, "--memory", 1024]
	config.vm.customize ["modifyvm", :id, "--cpus", 2]
	
end

# Replace the default chef json with your own
# See README.md for more info
def chef_json()
	return {
		"sites" => [

			{ # Example site with a database
				:id => "my_site", # Used for filenames, use only a-z, 0-9 and underscores
				:host => "database.dev",
				:aliases => [],
				:database => "my_db",
				:db_user => "my_db",
				:db_pass => "my_db",
			},
			{ # Example site that imports a database
				:id => "my_site_import", # Used for filenames, use only a-z, 0-9 and underscores
				:host => "import.dev",
				:aliases => [],
				:database => "my_import",
				:db_user => "my_import",
				:db_pass => "my_import",
				:db_import_file => "import.sql" # File needs to exist in (sites/import.dev)
			},
			{ # Example site that imports a database from remote host
				:id => "my_site_sync", # Used for filenames, use only a-z, 0-9 and underscores
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

		],

		"tz" => 'Europe/Stockholm',
		"mysql" => {
			"server_root_password" => "vagrant"
		},
		"oh_my_zsh" => {
			:users => [
				{
					:login => 'vagrant',
					:theme => 'blinks',
					:plugins => ['git', 'gem']
				}
			]
		}
	}
end