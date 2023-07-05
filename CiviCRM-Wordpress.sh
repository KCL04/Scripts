#!/bin/bash

if [ "$EUID" -ne 0 ]
then echo "Must be run as root"
fi

svc_acct="$USER";

# Install dependencies
sudo apt-get update;
sudo apt-get upgrade;
sudo apt-get install software-properties-common ca-certificates lsb-release apt-transport-https;
sudo add-apt-repository ppa:ondrej/php;
sudo apt update;
sudo apt-get install apache2 mysql-server libapache2-mod-php7.4 libtiff-tools php7.4 php7.4-bcmath php7.4-curl php7.4-gd php7.4-xml php7.4-mbstring php7.4-zip php7.4-intl php7.4-soap php7.4-mysql;

# Change ownership to current user
sudo chown -R $svc_acct /var/www/html;

# Install Wordpress
wget https://wordpress.org/latest.zip;
mv latest.zip /var/www/html/;
unzip /var/www/html/latest.zip -d /var/www/html/;

# Modify php.ini file

sudo sed -i 's/max_execution_time = 30/max_execution_time = 240/g' /etc/php/7.4/apache2/php.ini;
sudo sed -i 's/max_input_time = 60/max_input_time = 120/g' /etc/php/7.4/apache2/php.ini;
sudo sed -i 's/memory_limit = 128M/memory_limit = 256M/g' /etc/php/7.4/apache2/php.ini;
sudo sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 50M/g' /etc/php/7.4/apache2/php.ini;
sudo sed -i 's/;extension=curl/extension=curl/g' /etc/php/7.4/apache2/php.ini;
sudo sed -i 's/;extension=fileinfo/extension=fileinfo/g' /etc/php/7.4/apache2/php.ini;
sudo sed -i 's/;extension=gd2/extension=gd2/g' /etc/php/7.4/apache2/php.ini;
sudo sed -i 's/;extension=intl/extension=intl/g' /etc/php/7.4/apache2/php.ini;
sudo sed -i 's/;extension=mbstring/extension=mbstring/g' /etc/php/7.4/apache2/php.ini;
sudo sed -i 's/;extension=mysqli/extension=mysqli/g' /etc/php/7.4/apache2/php.ini;
sudo sed -i 's/;extension=soap/extension=soap/g' /etc/php/7.4/apache2/php.ini;

# Modify WP config file
mv /var/www/html/wordpress/wp-config-sample.php /var/www/html/wordpress/wp-config.php;
sudo sed -i 's/database_name_here/wordpress/g' /var/www/html/wordpress/wp-config.php;
sudo sed -i 's/username_here/wordpress/g' /var/www/html/wordpress/wp-config.php;
sudo sed -i 's/password_here/wordpress-password1/g' /var/www/html/wordpress/wp-config.php;

# Modify Apache2 Conf
sudo a2enmod rewrite;
if [ -s /etc/apache2/sites-available/wordpress.conf ]
then
	echo "Apache2 Config file already exists."
else
	sudo touch /etc/apache2/sites-available/wordpress.conf
	echo '<VirtualHost *:80>' | sudo tee -a /etc/apache2/sites-available/wordpress.conf
	echo $'\t'ServerAdmin webmaster@localhost | sudo tee -a /etc/apache2/sites-available/wordpress.conf
	echo $'\t'DocumentRoot /var/www/html/wordpress | sudo tee -a /etc/apache2/sites-available/wordpress.conf
	echo $'\t'"ErrorLog \${APACHE_LOG_DIR}/error.log" | sudo tee -a /etc/apache2/sites-available/wordpress.conf
	echo $'\t'"CustomLog \${APACHE_LOG_DIR}/access.log combined" | sudo tee -a /etc/apache2/sites-available/wordpress.conf
	echo $'\t'"<Directory /var/www/html/wordpress>" | sudo tee -a /etc/apache2/sites-available/wordpress.conf
	echo $'\t'$'\t'Options Indexes FollowSymLinks | sudo tee -a /etc/apache2/sites-available/wordpress.conf
	echo $'\t'$'\t'AllowOverride All | sudo tee -a /etc/apache2/sites-available/wordpress.conf
	echo $'\t'$'\t'Require all granted | sudo tee -a /etc/apache2/sites-available/wordpress.conf
	echo $'\t'"</Directory>" | sudo tee -a /etc/apache2/sites-available/wordpress.conf
	echo '</VirtualHost>' | sudo tee -a /etc/apache2/sites-available/wordpress.conf
fi
sudo a2ensite wordpress;
sudo systemctl restart apache2;
sudo a2dissite 000-default;
sudo systemctl reload apache2;

# Create Database
sudo mysql --execute='create database wordpress;';
sudo mysql --execute="create user 'wordpress'@'localhost' identified by 'wordpress-password1';";
sudo mysql --execute="grant all privileges on wordpress.* to 'wordpress'@'localhost';";
sudo mysql --execute="SET GLOBAL log_bin_trust_function_creators = 1;";

# Install CiviCRM
wget https://download.civicrm.org/civicrm-5.62.1-wordpress.zip -P /var/www/html/wordpress/wp-content/plugins/;
unzip /var/www/html/wordpress/wp-content/plugins/civi* -d /var/www/html/wordpress/wp-content/plugins/;
rm /var/www/html/backdrop/modules/*.zip;

# Change ownership to www-data
sudo chown -R www-data /var/www/html/wordpress;

# Continue Installation on browser
firefox localhost;
