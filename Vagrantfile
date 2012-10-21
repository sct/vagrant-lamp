# -*- mode: ruby -*-
# vi: set ft=ruby :

# This file should not contain any host/install specific info, put that into Vagranthost.rb

Vagrant::Config.run do |config|

	# Set box configuration
	config.vm.box = "precise32"
	config.vm.box_url = "http://files.vagrantup.com/precise32.box"

	# Load non-version-controlled host specific config file, if it exists
	if File.exist?('Vagranthost.rb')
		require './Vagranthost.rb'
		hostconfig(config)
		hostjson = chef_json();
	end

	# Forward MySql port on 33066, used for connecting admin-clients to localhost:33066
	config.vm.forward_port 3306, 33066

	# Set share folder permissions to 777 so that apache can write files
	config.vm.share_folder("v-root", "/vagrant", ".", :extra => 'dmode=777,fmode=666')

	# If you want to share using NFS uncomment this line (30x faster performance on mac/linux hosts)
	# http://vagrantup.com/v1/docs/nfs.html
	#config.vm.share_folder("v-root", "/vagrant", ".", :nfs => true)

	# Assign this VM to a host-only network IP, allowing you to access it via the IP.
	config.vm.network :hostonly, "33.33.33.10"

	# Enable provisioning with chef solo
	config.vm.provision :chef_solo do |chef|
		chef.cookbooks_path = "cookbooks"
		chef.add_recipe "vagrant_main"

		# If we have host specific json, use that
		if hostjson
			chef.json.merge!(hostjson)
		else
			# Default chef configuration, replaced by Vagranthost.rb
			chef.json.merge!({
				"sites" => [
					{ 
						:host => "local.dev",
						:aliases => [],
					},
				],
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
			})
		end

	end
end
