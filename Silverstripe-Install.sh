#!/bin/bash

if [ "$EUID" -ne 0 ]
then echo "Must be run as root"
fi

svc_acct="$USER";

# Install dependencies
sudo apt-get update;
sudo apt-get upgrade;
sudo apt-get install -y software-properties-common;
sudo add-apt-repository -y ppa:ondrej/php;
sudo add-apt-repository -y ppa:ondrej/apache2;
sudo apt-get update;
sudo apt-get install -y apache2 mysql-server php;
sudo apt-get install -y php-cli php-json php-common php-mysql php-zip php-gd php-mbstring php-curl php-xml php-bcmath libapache2-mod-php php-intl;

# Change ownership to current user
sudo chown -R $svc_acct /var/www/html;

# Install Silverstripe

curl -s https://getcomposer.org/installer | php;
sudo mv composer.phar /usr/local/bin/composer;
mkdir /var/www/html/silverstripe
composer create-project silverstripe/installer /var/www/html/silverstripe;

# Modify php.ini file
sudo sed -i 's/;extension=intl/extension=intl/g' /etc/php/8.2/apache2/php.ini;
sudo sed -i 's/;extension=curl/extension=curl/g' /etc/php/8.2/apache2/php.ini;
sudo sed -i 's/;extension=intl/extension=intl/g' /etc/php/8.2/cli/php.ini;
sudo sed -i 's/;extension=curl/extension=curl/g' /etc/php/8.2/cli/php.ini;

# Modify Apache2 Conf
sudo a2enmod rewrite;
if [ -s /etc/apache2/sites-available/silverstripe.conf ]
then
	echo "Apache2 Config file already exists."
else
	sudo touch /etc/apache2/sites-available/silverstripe.conf
	echo '<VirtualHost *:80>' | sudo tee -a /etc/apache2/sites-available/silverstripe.conf
	echo $'\t'ServerAdmin webmaster@localhost | sudo tee -a /etc/apache2/sites-available/silverstripe.conf
	echo $'\t'DocumentRoot /var/www/html/silverstripe | sudo tee -a /etc/apache2/sites-available/silverstripe.conf
	echo $'\t'"ErrorLog \${APACHE_LOG_DIR}/error.log" | sudo tee -a /etc/apache2/sites-available/silverstripe.conf
	echo $'\t'"CustomLog \${APACHE_LOG_DIR}/access.log combined" | sudo tee -a /etc/apache2/sites-available/silverstripe.conf
	echo $'\t'"<Directory /var/www/html/silverstripe>" | sudo tee -a /etc/apache2/sites-available/silverstripe.conf
	echo $'\t'$'\t'Options Indexes FollowSymLinks | sudo tee -a /etc/apache2/sites-available/silverstripe.conf
	echo $'\t'$'\t'AllowOverride All | sudo tee -a /etc/apache2/sites-available/silverstripe.conf
	echo $'\t'$'\t'Require all granted | sudo tee -a /etc/apache2/sites-available/silverstripe.conf
	echo $'\t'"</Directory>" | sudo tee -a /etc/apache2/sites-available/silverstripe.conf
	echo '</VirtualHost>' | sudo tee -a /etc/apache2/sites-available/silverstripe.conf
fi
sudo a2ensite silverstripe;
sudo systemctl restart apache2;
sudo a2dissite 000-default;
sudo systemctl reload apache2;

# Create Database
sudo mysql --execute='create database silverstripe;'; #default database name is silverstripe
sudo mysql --execute="create user 'silverstripe'@'localhost' identified by '<INSERT YOUR PASSWORD HERE>';"; #default username is silverstripe, update password
sudo mysql --execute="grant all privileges on silverstripe.* to 'silverstripe'@'localhost';"; #if username or database name is modified, update this line.

# Create Silverstripe environment variable
touch /var/www/html/silverstripe/.env;
echo SS_DATABASE_CLASS=\"MySQLDatabase\" >> /var/www/html/silverstripe/.env;
echo SS_DATABASE_NAME=\"silverstripe\" >> /var/www/html/silverstripe/.env;
echo SS_DATABASE_SERVER=\"localhost\" >> /var/www/html/silverstripe/.env;
echo SS_DATABASE_USERNAME=\"silverstripe\" >> /var/www/html/silverstripe/.env;
echo SS_DATABASE_PASSWORD=\"<INSERT DATABASE PASSWORD HERE>\" >> /var/www/html/silverstripe/.env; #insert password
echo SS_DEFAULT_ADMIN_USERNAME=\"silverstripe-admin\" >> /var/www/html/silverstripe/.env;
echo SS_DEFAULT_ADMIN_PASSWORD=\"<ADMIN PASSWORD HERE>\" >> /var/www/html/silverstripe/.env; #insert password
echo SS_ENVIRONMENT_TYPE=\"live\" >> /var/www/html/silverstripe/.env; # can be modified to dev

# Build Silverstripe
/var/www/html/silverstripe/vendor/bin/sake dev/build;

# Change ownership to www-data
sudo chown -R www-data /var/www/html/silverstripe;
