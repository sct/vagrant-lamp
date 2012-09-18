require_recipe "apt"
require_recipe "timezone"
require_recipe "git"
require_recipe "oh-my-zsh"
require_recipe "apache2"
require_recipe "apache2::mod_rewrite"
require_recipe "apache2::mod_ssl"
require_recipe "mysql::server"
require_recipe "php"
require_recipe "php::module_mysql"
require_recipe "apache2::mod_php5"

# Install packages
%w{ debconf vim screen mc subversion curl tmux make g++ libsqlite3-dev }.each do |a_package|
	package a_package
end

# Install ruby gems
%w{ rake mailcatcher }.each do |a_gem|
	gem_package a_gem
end

# Generate selfsigned ssl
execute "make-ssl-cert" do
	command "make-ssl-cert generate-default-snakeoil --force-overwrite"
	ignore_failure true
	action :nothing
end

# Install phpmyadmin
cookbook_file "/tmp/phpmyadmin.deb.conf" do
	source "phpmyadmin.deb.conf"
end
bash "debconf_for_phpmyadmin" do
	code "debconf-set-selections /tmp/phpmyadmin.deb.conf"
end
package "phpmyadmin"

# Install Xdebug
php_pear "xdebug" do
	action :install
end
template "#{node['php']['ext_conf_dir']}/xdebug.ini" do
	source "xdebug.ini.erb"
	owner "root"
	group "root"
	mode "0644"
	action :create
	notifies :restart, resources("service[apache2]"), :delayed
end

# Install Webgrind
git "/var/www/webgrind" do
	repository 'git://github.com/jokkedk/webgrind.git'
	reference "master"
	action :sync
end
template "#{node[:apache][:dir]}/conf.d/webgrind.conf" do
	source "webgrind.conf.erb"
	owner "root"
	group "root"
	mode 0644
	action :create
	notifies :restart, resources("service[apache2]"), :delayed
end

# Install php-curl
package "php5-curl" do
	action :install
end

# Get eth1 ip
eth1_ip = node[:network][:interfaces][:eth1][:addresses].select{|key,val| val[:family] == 'inet'}.flatten[0]

# Setup MailCatcher
bash "mailcatcher" do
	code "mailcatcher --http-ip #{eth1_ip} --smtp-port 25"
	not_if "ps ax | grep -v grep | grep mailcatcher";
end
template "#{node['php']['ext_conf_dir']}/mailcatcher.ini" do
	source "mailcatcher.ini.erb"
	owner "root"
	group "root"
	mode "0644"
	action :create
end



# Disable default site
apache_site "default" do
	enable false  
end

node['sites'].each do |site|

	if site.include?(:webroot)
		site_docroot = "/vagrant/sites/#{site[:host]}/#{site[:webroot]}"
	else
		site_docroot = "/vagrant/sites/#{site[:host]}"
	end

	# Add site to apache config
	web_app site[:host] do
		template "sites.conf.erb"
		server_name site[:host]
		server_aliases site[:aliases]
		docroot site_docroot
	end

	# Add site info in /etc/hosts
	bash "hosts" do
	 code "echo 127.0.0.1 #{site[:host]}  >> /etc/hosts"
	end

	execute "mysql-vagrant-user" do
		command "/usr/bin/mysql -u root -p\"#{node['mysql']['server_root_password']}\" -e \"GRANT ALL PRIVILEGES ON *.* TO 'vagrant'@'%' IDENTIFIED BY 'vagrant' WITH GRANT OPTION ;\" ";
	end
	

	if site[:framework] == 'magento'

		# Create magento settings file
		# template "#{site[:path]}/app/etc/local.xml" do
		#   source "magento.local.xml.erb"
		#   variables(
		#     :host     => 'localhost',
		#     :user     => 'vagrant',
		#     :pass     => 'vagrant',
		#     :db       => 'vagrant',
		#     :mcrypt   => '59883184cd773361656e056f88a921ef'
		#   )
		# end

		# Clear magento cache
		execute "clear-magento-cache" do
			command "rm -rfv #{site_docroot}/var/cache/*";
			only_if "test -d #{site_docroot}/var/cache/";
		end

		# Add magento cron
		template "/etc/cron.d/magento" do
			source "magento.cron.erb"
			owner "root"
			group "root"
			mode "0600"
			variables(
				:magentoroot => site_docroot
			)
		end

	end

	# Setup database
	if site.include?(:database)

		#execute "mysql-install-privileges" do
		#	command "/usr/bin/mysql -u root -p\"#{node['mysql']['server_root_password']}\" < #{node['mysql']['conf_dir']}/grants.sql"
		#	action :nothing
		#end
		template "#{node['mysql']['conf_dir']}/grants.sql" do
			source "grants.sql.erb"
			owner "root"
			group "root"
			mode "0600"
			variables(
				:user     => site[:db_user],
				:password => site[:db_pass],
				:database => site[:database]
			)
			#notifies :run, "execute[mysql-install-privileges]", :immediately
		end

		execute "create #{site[:database]} database" do
			command "/usr/bin/mysqladmin -u root -p\"#{node['mysql']['server_root_password']}\" create #{site[:database]}"
			not_if "/usr/bin/mysql -u root -p\"#{node['mysql']['server_root_password']}\" -e \"SHOW DATABASES LIKE '#{site[:database]}'\" | grep '#{site[:database]}' ";
		end

		# Import database
		if site.include?(:db_import_file)

			execute "load-mysql-#{site[:database]}" do
				command "/usr/bin/mysql -u root -p\"#{node['mysql']['server_root_password']}\" #{site[:database]} < /vagrant/sites/#{site[:host]}/#{site[:db_import_file]}"
				only_if "test -f /vagrant/sites/#{site[:host]}/#{site[:db_import_file]}"
			end

		end

		# Sync database
		if site.include?(:db_sync)

			# Only done if vagrant-dump-{DB}.sql does not exist
			execute "load-mysql-#{site[:database]}" do
				command "/usr/bin/mysql -u root -p\"#{node['mysql']['server_root_password']}\" #{site[:database]} < /home/vagrant/vagrant-dump-#{site[:database]}.sql"
				only_if "test -f /home/vagrant/vagrant-dump-#{site[:database]}.sql"
			end
			execute "dump-mysql-#{site[:database]}" do
				command \
					"ssh #{site[:db_sync][:ssh_user]}@#{site[:db_sync][:ssh_host]} -i /vagrant/#{site[:db_sync][:ssh_private_key]} -o StrictHostKeyChecking=no " +\
					"\"mysqldump -u root -p#{site[:db_sync][:mysql_root_pass]} #{site[:db_sync][:remote_database]} > /tmp/vagrant-dump.sql \" && " +\
					"scp -i /vagrant/#{site[:db_sync][:ssh_private_key]} -o StrictHostKeyChecking=no " +\
					"#{site[:db_sync][:ssh_user]}@#{site[:db_sync][:ssh_host]}:/tmp/vagrant-dump.sql /home/vagrant/vagrant-dump-#{site[:database]}.sql"
				creates "/home/vagrant/vagrant-dump-#{site[:database]}.sql"
				notifies :run, "execute[load-mysql-#{site[:database]}]", :immediately
			end

		end

		# Set base url for magento
		execute "magento-alter-dump" do
			command "/usr/bin/mysql -u root -p\"#{node['mysql']['server_root_password']}\" #{site[:database]} -e \"" +\
			"UPDATE core_config_data SET value = 'http://#{site[:host]}/' WHERE path = 'web/unsecure/base_url' ; " +\
			"UPDATE core_config_data SET value = 'https://#{site[:host]}/' WHERE path = 'web/secure/base_url' ; \" ";
			only_if { site[:framework] == 'magento' }
		end


	end


end

service "apache2" do
	notifies :restart, resources(:service => "apache2"), :delayed
end
