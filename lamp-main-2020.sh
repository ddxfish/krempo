#!/bin/bash
#script to set up aws as a web server.
#Version 2020.1
#Today is: 5-23-2020
#Ubuntu is 20.04 LTS

#run it as root!!!
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

echo This will install LAMP.
echo Press Ctrl + C to Cancel or ENTER to continue
read nothing

#aliases install, separate file if wanted
clear
echo "Bash Aliases"
echo "Edits root and ubuntu .bash_aliases with new command aliases and prefs"
read -r -p "Do you want to run this step? [y/N] " response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]
then
    chmod +x lamp-bash-alias.sh 
    /bin/bash lamp-bash-alias.sh
else
    echo "We are not adding any aliases"
fi
sleep 3


#upgrade ubuntu and install vim mlocate
apt-get update
apt-get upgrade -y
apt-get -y install vim mlocate
updatedb


#apache, PHP, MySQL, and opcache
apt-get -y install apache2 php7.4 libapache2-mod-php7.4 php7.4-mysql php7.4-curl php7.4-gd php-imagick php-memcache php7.4-xmlrpc php7.4-mbstring php7.4-xml mysql-server mysql-client php7.4-opcache php-apcu phpmyadmin
#shutdown phpmyadmin every night
(crontab -l ; echo "0 23 * * * mv /usr/share/phpmyadmin /usr/share/phpmyadminx") | sort - | uniq - | crontab -
#secure SQL
mysql_secure_installation
a2enmod rewrite
systemctl restart apache2

#Change default apache directory
#/var/www/default/html
mkdir -p /var/www/default/html
mv /var/www/html/* /var/www/default/html
sed -i 's#/var/www/html#/var/www/default/html#g' /etc/apache2/sites-available/000-default.conf
rm -fr /var/www/html

#install ssl, enable default site
a2enmod ssl
a2ensite default-ssl
systemctl restart apache2


#Security for Apache
#sed -i 's/ServerTokens OS/ServerTokens Prod/g' /etc/apache2/conf-available/security.conf
#sed -i 's/ServerSignature On/ServerSignature Off/g' /etc/apache2/conf-available/security.conf
#Disallow indexes by default, denied ACCESS TO var/www
#perl -0777 -i.original -pe 's#<Directory /var/www/>\n\tOptions Indexes FollowSymLinks\n\tAllowOverride None\n\tRequire all granted#<Directory /var/www/>\n\tOptions -Indexes +FollowSymLinks\n\tAllowOverride None\n\tRequire all denied#igs' /etc/apache2/apache2.conf
#perl -0777 -i.original -pe 's#<Directory />\n\tOptions FollowSymLinks#<Directory />\n\tOptions None#igs' /etc/apache2/apache2.conf
#diff /etc/apache2/apache2.conf{,.original}




#set up ufw
apt-get -y install ufw
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp 
ufw allow 10099/tcp
ufw allow 65420/tcp
ufw enable
ufw status




#extra security for SSH
sed -i 's/#Port 22/Port 65420/g' /etc/ssh/sshd_config
sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin prohibit-password/g' /etc/ssh/sshd_config
sed -i 's/X11Forwarding/#X11Forwarding/g' /etc/ssh/sshd_config
echo --------------------------------
echo I am restarting SSHD on port 65420
echo -------------------------------------
echo press any key to continue
read nothing
systemctl restart sshd





#set up webmin using apt
echo deb https://download.webmin.com/download/repository sarge contrib >> /etc/apt/sources.list
cd /root/setup
wget http://www.webmin.com/jcameron-key.asc
apt-key add jcameron-key.asc
apt-get update
apt-get -y install perl libnet-ssleay-perl openssl libauthen-pam-perl libpam-runtime libio-pty-perl apt-show-versions python
apt-get -y install webmin
sed -i 's#10000#10099#g' /etc/webmin/miniserv.conf
systemctl restart webmin
#shutdown webmin nightly
(crontab -l ; echo "0 23 * * * systemctl stop webmin") | sort - | uniq - | crontab -


clear
echo "This next step will:"
echo "Install a virtual host (website)"
echo "Create a new database for a website"
echo "Install Wordpress for this website"
read -r -p "Do you want to run all of this? [y/N] " response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]
then
    echo "Installing website..."
else
	echo "You have completed the setup"
    exit 1
fi

#Set up Virtual Host and root dir for a site
echo ---------------------------------------------------
echo "Enter the primary website domain without www."
read websitename
mkdir -p /var/www/$websitename/html
touch /etc/apache2/sites-available/$websitename.conf
echo "<VirtualHost *:80>
	DocumentRoot /var/www/$websitename/html
	ServerName $websitename
	ServerAlias www.$websitename
	<Directory /var/www/$websitename/html>
		Options -Indexes +FollowSymLinks
		AllowOverride All
		Require all granted
	</Directory>
	CustomLog       /var/log/apache2/$websitename-nonssl-access.log combined
	ErrorLog        /var/log/apache2/$websitename-nonssl-error.log
</VirtualHost>
#<VirtualHost *:443>
#	SSLEngine on
#
#	SSLCertificateFile      /etc/ssl/$websitename.crt
#	SSLCertificateKeyFile   /etc/ssl/$websitename.key
#
#	ServerName      $websitename
#	ServerAlias 	www.$websitename
#	DocumentRoot    /var/www/$websitename/html
#
#	CustomLog       /var/log/apache2/$websitename-access.log combined
#	ErrorLog        /var/log/apache2/$websitename-error.log
#
#	<Directory /var/www/$websitename/html>
#		Options -Indexes +FollowSymLinks
#		AllowOverride All
#		Require all granted
#	</Directory>
#</VirtualHost>
" | tee /etc/apache2/sites-available/$websitename.conf
a2ensite $websitename.conf
systemctl restart apache2


#Wordpress files
cd /var/www/$websitename
rm latest.tar.gz
rm -fr wordpress
wget https://wordpress.org/latest.tar.gz
tar xf latest.tar.gz
mv -f /var/www/$websitename/wordpress/* /var/www/$websitename/html/
chown -R www-data:www-data /var/www
rm latest.tar.gz
rm -fr wordpress

#Database
echo Input database name:
read databasename
echo Input database username:
read databaseusername
echo Input database user password
read databaseuserpassword
echo ----------------------
echo Get your root password ready, passing to mysql!!!!

mysql -u root -p -e "CREATE DATABASE $databasename"
mysql -u root -p -D $databasename -e "GRANT ALL PRIVILEGES ON $databasename.* TO $databaseusername@'localhost' IDENTIFIED BY '$databaseuserpassword';"

#Install SSL Certificate using Let's Encrypt - separate file
clear
echo "Let's Encrypt?"
echo "uses the automatic tool from Let's Encrypt to set up SSL certificate."
read -r -p "Do you want to run this step? [y/N] " response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]
then
    chmod +x lamp-letsencrypt.sh 
    /bin/bash lamp-letsencrypt.sh
else
    echo "Skipping Let's Encrypt"
fi

echo "----------------------------"
echo "We have reached the end of the script!"
echo "----------------------------"
