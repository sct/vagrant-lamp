# -*- mode: ruby -*-
# vi: set ft=ruby :

# If you copy this file to Vagranthost.rb it will not be version controlled so you can use it to store your personal configs


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

			{ # Example site, check README for more
				:id => "my_site", # Used for filenames, use only a-z, 0-9 and underscores
				:host => "database.dev",
				:aliases => [],
			},

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