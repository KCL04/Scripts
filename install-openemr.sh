#!/bin/bash

if [ "$EUID" -ne 0 ]
then echo "Must be run as root"
fi

svc_acct="$USER";

# Install dependencies
sudo apt-get update;
sudo apt-get upgrade;
sudo apt-get install apache2 mysql-server libapache2-mod-php libtiff-tools php8.1 php8.1-mysql php8.1-cli php8.1-gd php8.1-xsl php8.1-curl php8.1-soap imagemagick php8.1-zip php8.1-ldap php8.1-mbstring;

# Change ownership to current user
sudo chown -R $svc_acct /var/www/html;

# Install OpenEMR
wget https://sourceforge.net/projects/openemr/files/OpenEMR%20Current/7.0.0.2/openemr-7.0.0.tar.gz/download;
mv download download.tar.gz;
tar -pxvzf download.tar.gz;
mv openemr-7.0.0 /var/www/html/openemr;
rm download.tar.gz;

# Modify php.ini file

sudo sed -i 's/max_execution_time = 30/max_execution_time = 60/g' /etc/php/8.1/apache2/php.ini;
sudo sed -i 's/max_input_time = 60/max_input_time = -1/g' /etc/php/8.1/apache2/php.ini;
sudo sed -i 's/max_execution_time = 30/max_execution_time = 60/g' /etc/php/8.1/apache2/php.ini;
sudo sed -i 's/;max_input_vars = 1000/max_input_vars = 3000/g' /etc/php/8.1/apache2/php.ini;
sudo sed -i 's/memory_limit = 128M/memory_limit = 512M/g' /etc/php/8.1/apache2/php.ini;
sudo sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 30M/g' /etc/php/8.1/apache2/php.ini;
sudo sed -i 's/post_max_size = 8M/post_max_size = 30M/g' /etc/php/8.1/apache2/php.ini;
sudo sed -i 's/~E_DEPRECATED/~E_NOTICE \& \~E_DEPRECATED/g' /etc/php/8.1/apache2/php.ini;
sudo sed -i 's/;mysqli.allow_local_infile = On/mysqli.allow_local_infile = On/g' /etc/php/8.1/apache2/php.ini;

# Modify Apache2 Conf
sudo a2enmod rewrite;
if [ -s /etc/apache2/sites-available/openemr.conf ]
then
	echo "Apache2 Config file already exists."
else
	sudo touch /etc/apache2/sites-available/openemr.conf
	echo '<VirtualHost *:80>' | sudo tee -a /etc/apache2/sites-available/openemr.conf
	echo $'\t'ServerAdmin webmaster@localhost | sudo tee -a /etc/apache2/sites-available/openemr.conf
	echo $'\t'DocumentRoot /var/www/html/openemr | sudo tee -a /etc/apache2/sites-available/openemr.conf
	echo $'\t'"ErrorLog \${APACHE_LOG_DIR}/error.log" | sudo tee -a /etc/apache2/sites-available/openemr.conf
	echo $'\t'"CustomLog \${APACHE_LOG_DIR}/access.log combined" | sudo tee -a /etc/apache2/sites-available/openemr.conf
	echo $'\t'"<Directory /var/www/html/openemr>" | sudo tee -a /etc/apache2/sites-available/openemr.conf
	echo $'\t'$'\t'Options Indexes FollowSymLinks | sudo tee -a /etc/apache2/sites-available/openemr.conf
	echo $'\t'$'\t'AllowOverride FileInfo | sudo tee -a /etc/apache2/sites-available/openemr.conf
	echo $'\t'$'\t'Require all granted | sudo tee -a /etc/apache2/sites-available/openemr.conf
	echo $'\t'"</Directory>" | sudo tee -a /etc/apache2/sites-available/openemr.conf
	echo $'\t'"<Directory /var/www/html/openemr/sites>" | sudo tee -a /etc/apache2/sites-available/openemr.conf
	echo $'\t'$'\t'AllowOverride None | sudo tee -a /etc/apache2/sites-available/openemr.conf
	echo $'\t'"</Directory>" | sudo tee -a /etc/apache2/sites-available/openemr.conf
	echo $'\t'"<Directory /var/www/html/openemr/sites/*/documents>" | sudo tee -a /etc/apache2/sites-available/openemr.conf
	echo $'\t'$'\t'Require all denied | sudo tee -a /etc/apache2/sites-available/openemr.conf
	echo $'\t'"</Directory>" | sudo tee -a /etc/apache2/sites-available/openemr.conf
	echo '</VirtualHost>' | sudo tee -a /etc/apache2/sites-available/openemr.conf
fi
sudo a2ensite openemr;
sudo systemctl restart apache2;
sudo a2dissite 000-default;
sudo systemctl reload apache2;

# Create Database
sudo mysql --execute='create database openemr;'; #default databasename is openemr
sudo mysql --execute="create user 'openemr'@'localhost' identified by '<INSERT YOUR PASSWORD HERE>';"; #default username is openemr
sudo mysql --execute="grant all privileges on openemr.* to 'openemr'@'localhost';"; #if database name and username is different, update this line.

# Change ownership to www-data
sudo chown -R www-data /var/www/html/openemr;
