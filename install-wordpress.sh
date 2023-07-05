#!/bin/bash

if [ "$EUID" -ne 0 ]
then echo "Must be run as root"
fi

svc_acct="$USER";

# Install dependencies
sudo apt-get update;
sudo apt-get upgrade;
sudo apt-get install mysql-server apache2 php php-mysql;

# Change ownership to current user
sudo chown -R $svc_acct /var/www/html;

# Install Wordpress
wget https://wordpress.org/latest.zip;
mv latest.zip /var/www/html/;
unzip /var/www/html/latest.zip -d /var/www/html/;

# Modify php.ini file

sudo sed -i 's/;extension=mysqli/extension=mysqli/g' /etc/php/8.1/apache2/php.ini;

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

# Change ownership to www-data
sudo chown -R www-data /var/www/html/wordpress;
