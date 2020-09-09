#!/bin/bash
#script to set up aws as a web server
#Beachside Technology
#Version 2020.2
#Today is: 9-8-2020
#Ubuntu is 20.04.1 LTS

#run it as root!!!
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

echo This will install LAMP.
echo Press Ctrl + C to Cancel or ENTER to continue
read nothing

mkdir -p /root/setup/krempo
cp ./* /root/setup/krempo
cd /root/setup

#aliases install, separate file if wanted
clear
echo "Bash Aliases"
echo "Edits root and main user .bash_aliases with new command aliases and prefs"
echo "We recommend you do this and check .bash_aliases for a list of alias commands"
read -r -p "Do you want to run this step? [y/N] " response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]
then
    chmod +x /root/setup/krempo/lamp-bash-alias.sh 
    /bin/bash /root/setup/krempo/lamp-bash-alias.sh
else
    echo "fine, we are not adding any aliases..........."
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
clear
echo "Securing SQL. Press N for the first one and Y for the rest."
read nothing
mysql_secure_installation
a2enmod rewrite
#change default file upload size in php.ini
sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 16M/g' /etc/php/7.4/apache2/php.ini
sed -i 's/post_max_size = 8M/post_max_size = 16M/g' /etc/php/7.4/apache2/php.ini
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
sed -i 's/ServerTokens OS/ServerTokens Prod/g' /etc/apache2/conf-available/security.conf
sed -i 's/ServerSignature On/ServerSignature Off/g' /etc/apache2/conf-available/security.conf
#Disallow indexes by default, denied ACCESS TO var/www
perl -0777 -i.original -pe 's#<Directory /var/www/>\n\tOptions Indexes FollowSymLinks\n\tAllowOverride None\n\tRequire all granted#<Directory /var/www/>\n\tOptions -Indexes +FollowSymLinks\n\tAllowOverride None\n\tRequire all denied#igs' /etc/apache2/apache2.conf
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


#Webmin installation on port 10099
read -r -p "Do you want webmin installed? [y/N] " response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]
then
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
else
	echo "no webmin for you"
    exit 1
fi



#begin actual website installation
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
	echo "You have completed the setup, goodbye!"
	read nothing
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

clear
#Database
echo Input new database name:
read databasename
echo Input new database username:
read databaseusername
echo Input new database user password:
read databaseuserpassword
echo ----------------------
echo Get your root password ready.
echo This will ask for your root password thrice.
echo 1- Create DB, 2- Create User, 3- Grant
echo Go ahead with your root pass three times:

#create database with info given
mysql -u root -p -e "CREATE DATABASE $databasename"
mysql -u root -p -e "CREATE USER '$databaseusername'@'localhost' IDENTIFIED BY '$databaseuserpassword';"
mysql -u root -p -D $databasename -e "GRANT ALL ON $databasename.* TO '$databaseusername'@'localhost';"

#install wordpress CLI tool
curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
chmod +x wp-cli.phar
sudo mv wp-cli.phar /usr/local/bin/wp

clear
cd /var/www/$websitename/html
#install wordpress with random password
wordpresspass=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1`
#creat config
wp config create --allow-root --dbname=$databasename --dbuser=$databaseusername --dbpass=$databaseuserpassword
#create DB -- might fail due to already created
wp db create --allow-root
#install the core
wp core install --allow-root --url=$websitename --title=$websitename --admin_user=supervisor --admin_password=$wordpresspass --admin_email=info@$websitename
pause 3

#MAKE SURE USER TAKES THE LOGIN INFO
echo Copy your Wordpress login information:
echo -----------------------------------
echo host: http://$websitename/wp-admin/
echo user: supervisor
echo pass: $wordpresspass
read nothing
echo Are you really sure you got that? Its important.
read nothing

cd /root/krempo
#Install SSL Certificate using Let's Encrypt - separate file
clear
echo "Let's Encrypt?"
echo "uses the automatic tool from Let's Encrypt to set up SSL certificate."
read -r -p "Do you want to run this step? [y/N] " response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]
then
    chmod +x /root/setup/krempo/lamp-letsencrypt.sh 
    /bin/bash /root/setup/krempo/lamp-letsencrypt.sh
else
    echo "Skipping Let's Encrypt"
fi

#automatic backups every week
clear
echo "Set Up Backups"
echo "Creates weekly backups of the sql and website files to /root/website-backups"
echo "You really need 20GB or more on your root volume for this!!"
read -r -p "Do you want to run this step? [y/N] " response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]
then
    chmod +x /root/setup/krempo/lamp-backups.sh 
    /bin/bash /root/setup/krempo/lamp-backups.sh $websitename $databasename $databaseusername $databaseuserpassword
else
    echo "We are not adding backup scripts"
fi
sleep 3

#Mod Security
clear
echo "mod_security?"
echo "Advanced security plugin for Apache"
echo "Sometimes blocks legitimate use!!!!"
echo "Probably don't run this unless you can tweak it"
read -r -p "Do you want to install mod_security? [y/N] " response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]
then
    chmod +x /root/setup/krempo/lamp-modsecurity2.sh
    /bin/bash /root/setup/krempo/lamp-modsecurity2.sh
else
    echo "Skipping Mod Security"
fi
sleep 3

echo "----------------------------"
echo "We have reached the end of the script!"
echo "Visit your website $websitename now in a browser"
echo "----------------------------"
read nothing
