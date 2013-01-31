# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant::Config.run do |config|

	#################################
  # Base box and vm configuration #
  #################################

	# Set base box to be used
	config.vm.box = "precise32"

	# Url of base box in case vagrant needs to download it
	config.vm.box_url = "http://files.vagrantup.com/precise32.box"

	# Set the vm's host name.
	config.vm.host_name = "vagrant"

	# If you give the VM more than 1 cpu, it might lose 100x performance.
	config.vm.customize ["modifyvm", :id, "--cpus", 1]

	# Set the memory size (RAM)
	config.vm.customize ["modifyvm", :id, "--memory", 1024]

	# Forward MySql port on 33066, used for connecting admin-clients to localhost:33066
	config.vm.forward_port 3306, 33066

	# Set share folder permissions to 777 so that apache can write files
	#config.vm.share_folder("v-root", "/vagrant", ".", :extra => 'dmode=777,fmode=666')

	# If you want to share using NFS uncomment this line (30x faster performance on mac/linux hosts)
	# http://vagrantup.com/v1/docs/nfs.html
	#config.vm.share_folder("v-root", "/vagrant", ".", :nfs => true)

	# Assign this VM to a host-only network IP, allowing you to access it via the IP.
	config.vm.network :hostonly, "33.33.33.10"

	# VirtualBox performance improvements
	# Found here: https://github.com/xforty/vagrant-drupal/blob/master/Vagrantfile
	config.vm.customize ["modifyvm", :id, "--nictype1", "virtio"]
	config.vm.customize ["modifyvm", :id, "--nictype2", "virtio"]
	config.vm.customize ["storagectl", :id, "--name", "SATA Controller", "--hostiocache", "off"]


  #################################
  # Librarian                     #
  #################################

	# Only run if "up" was called
  if ARGV.first == "up"

    # Path to our cookbooks folder
    cookbooks_path = File.expand_path(File.dirname(__FILE__)) + "/cookbooks"

    # Run librarian if cookbooks folder does not exist or is empty
    if !Dir::exists?(cookbooks_path) || (Dir.entries(cookbooks_path).size < 3)
      puts 'Running "librarian-chef install"...'
      puts `librarian-chef install`
    end
  end


  #################################
  # Provisioners                  #
  #################################

	config.vm.provision :chef_solo do |chef|

		# The librarian gem controls the "cookbook" folder, do not touch it. If you
    # need to create site-specific cookbooks, place them in "site-cookbooks".
		chef.cookbooks_path = ["cookbooks", "cookbooks-custom"]

		# Path to data bags (our sites config)
		chef.data_bags_path = "databags"

		# Default top level chef recipe
		chef.add_recipe "vagrant_main"

		#chef.log_level = "debug"

		# Custom chef json configuration
		chef.json.merge!({
			:tz => 'Europe/Stockholm',
			:mysql => {
				"server_root_password" => "vagrant",
				"server_debian_password" => "vagrant",
				"server_repl_password" => "vagrant"
			},
			:oh_my_zsh => {
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
