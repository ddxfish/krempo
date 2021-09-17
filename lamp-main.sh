#!/bin/bash
#KREMPO - script to set up aws instance as a web server
#Version 2021.3
#Today is 9-17-2021
#Ubuntu is 20.04.3 LTS


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
touch /root/setup/krempo/logininfo.txt

clear
echo "Create your root password for this server:"
read rootpass
echo -e "$rootpass\n$rootpass" | passwd root
echo "Root: $rootpass" | tee -a /root/setup/krempo/logininfo.txt

#init
InstallWebmin=0
InstallVirtualHost=0
InstallLetsEncrypt=0
InstallModSecurity=0
InstallWordPress=0
InstallBackupScript=0

clear
#used later for webmin
read -r -p "Krempo: Do you want webmin installed? [y/N] " response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]
then
    InstallWebmin=1
fi

clear
#used later, lets get info for the install
echo "Krempo: Do you want to install a Virtual Host during install?"
echo "You set a domain and directory where its files live"
read -r -p "Do you want to do this? [y/N] " response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]
then
    InstallVirtualHost=1
    #Set up Virtual Host and root dir for a site
    clear
    echo "Krempo---------------------------------------------------"
    echo "Enter the primary website domain without your subdomain"
    echo "Example: mysite.com"
    read websitename
    clear
    echo "Please enter the subdomain you are using with $websitename"
    echo "Do not name it default"
    echo "Example: www"
    echo "Example2: new"
    echo "Example3: <leave blank for no subdomain>"
    read subdomain
    if [[ "$subdomain" == "" ]]; then
        subdomain="default"
        fulldomain=$websitename
    else
        fulldomain=$subdomain.$websitename
    fi
    if [[ "$subdomain" == "www" ]]; then
        read -r -p "Would you like both www.$websitename and $websitename to both work for this host? [y/N] " response
        if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
            serveralias="ServerAlias $websitename"
        else
            serveralias=""
        fi
    fi
    #get this for later to automate the script
    clear
    echo "Let's Encrypt?"
    echo "uses the automatic tool from Let's Encrypt to set up SSL certificate."
    read -r -p "Do you want to run this step? [y/N] " response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]
    then
        InstallLetsEncrypt=1
    fi
    #Mod Security
    clear
    echo "mod_security?"
    echo "Advanced security plugin for Apache - MAY BLOCK LEGITIMATE USE"
    echo "Say N or No if you aren't sure!"
    read -r -p "Do you want to install mod_security? [y/N] " response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]
    then
        InstallModSecurity=1
    fi
fi
clear

#used later, lets get WordPress stuff
echo "Create a new database and install WordPress?"
read -r -p "Do you want to do this step? [y/N] " response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]
then
    InstallWordPress=1
    #Database
    databasebase=`echo $websitename | cut -c1-5`
    databasename=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 4 | head -n 1 | sed s/^/$databasebase/g`
    databaseusername=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 4 | head -n 1 | sed s/^/$databasebase/g`
    databaseuserpassword=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 14 | head -n 1`
    wordpresspass=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 16 | head -n 1`
    clear
    echo "Copy this data for later"
    echo "You can find it in /root/setup/krempo/logininfo.txt"
    echo "DB Name: $databasename" | tee -a /root/setup/krempo/logininfo.txt
    echo "DB User: $databaseusername" | tee -a /root/setup/krempo/logininfo.txt
    echo "DB Pass: $databaseuserpassword" | tee -a /root/setup/krempo/logininfo.txt
    echo -------------- | tee -a /root/setup/krempo/logininfo.txt
    echo "WP host: http://$fulldomain/wp-admin/" | tee -a /root/setup/krempo/logininfo.txt
    echo "WP user: supervisor" | tee -a /root/setup/krempo/logininfo.txt
    echo "WP pass: $wordpresspass" | tee -a /root/setup/krempo/logininfo.txt
    echo -------------- | tee -a /root/setup/krempo/logininfo.txt
    echo "press enter to continue"
    read nothing
    #automatic backups every week
    clear
    echo "Set Up Backups?"
    echo "Simple script run by cron to backup files and DB weekly to /root/website-backups"
    echo "You really need 30GB or more on your root volume for this!!"
    read -r -p "Do you want to run this step? [y/N] " response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]
    then
        InstallBackupScript=1
    fi
fi





#begin actual script

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

#Secure SQL - automatic
#make sure root has password
rootdbpass=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 14 | head -n 1`
mysqladmin -u root password $rootdbpass
#no anonymous user
mysql -e "DROP USER ''@'localhost'"
#drop empty user for our hostname (hopefully)
mysql -e "DROP USER ''@'$(hostname)'"
#Test database delete if exist
mysql -e "DROP DATABASE IF EXISTS test"
#Reloading causes passwords to be required
mysql -e "FLUSH PRIVILEGES"


#change some apache variables for performance and functions
a2enmod rewrite
#change default file upload size in php.ini
sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 16M/g' /etc/php/7.4/apache2/php.ini
sed -i 's/post_max_size = 8M/post_max_size = 16M/g' /etc/php/7.4/apache2/php.ini
sed -i 's/memory_limit = 128M/memory_limit = 256M/g' /etc/php/7.4/apache2/php.ini
systemctl restart apache2

#Change default apache directory to match how we do it
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
echo "y" | ufw enable
ufw reload
ufw status




#extra security for SSH
sed -i 's/#Port 22/Port 65420/g' /etc/ssh/sshd_config
sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin prohibit-password/g' /etc/ssh/sshd_config
sed -i 's/X11Forwarding/#X11Forwarding/g' /etc/ssh/sshd_config
echo --------------------------------
echo Krempo: I am restarting SSHD on port 65420
echo -------------------------------------
systemctl restart sshd


#Webmin installation on port 10099
#read -r -p "Krempo: Do you want webmin installed? [y/N] " response
if [[ $InstallWebmin == 1 ]]
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
fi



#Virtual Hosts section (pulled variables from up top)
#Script exits here if Virtual Host is not set up
clear
if [[ $InstallVirtualHost == 1 ]]
then
	echo "Installing website..."
else
	echo "You have completed the setup, goodbye!"
	echo "Open /root/setup/krempo/logininfo.txt for your login details"
	read nothing
	exit 1
fi

websitedir="/var/www/$websitename/$subdomain/html"

mkdir -p $websitedir
touch /etc/apache2/sites-available/$fulldomain.conf
echo "<VirtualHost *:80>
	DocumentRoot $websitedir
	ServerName $fulldomain
	$serveralias
	<Directory $websitedir>
		Options -Indexes +FollowSymLinks
		AllowOverride All
		Require all granted
	</Directory>
	CustomLog       /var/log/apache2/$fulldomain-nonssl-access.log combined
	ErrorLog        /var/log/apache2/$fulldomain-nonssl-error.log
</VirtualHost>
#<VirtualHost *:443>
#	SSLEngine on
#
#	SSLCertificateFile      /etc/ssl/$fulldomain.crt
#	SSLCertificateKeyFile   /etc/ssl/$fulldomain.key
#
#	ServerName      $fulldomain
#	$serveralias
#	DocumentRoot    $websitedir
#
#	CustomLog       /var/log/apache2/$fulldomain-access.log combined
#	ErrorLog        /var/log/apache2/$fulldomain-error.log
#
#	<Directory $websitedir>
#		Options -Indexes +FollowSymLinks
#		AllowOverride All
#		Require all granted
#	</Directory>
#</VirtualHost>
" | tee /etc/apache2/sites-available/$fulldomain.conf
a2ensite $fulldomain.conf
systemctl restart apache2


#Install database and WordPress from variables we pulled up top
if [[ $InstallWordPress == 1 ]]
then
    #lamp-wordpress.sh $websitename $subdomain $websitedir $databasename $databaseusername $databaseuserpassword $fulldomain
    chmod +x /root/setup/krempo/lamp-wordpress.sh
    /bin/bash /root/setup/krempo/lamp-wordpress.sh $websitename $subdomain $websitedir $databasename $databaseusername $databaseuserpassword $fulldomain $wordpresspass $rootpass
fi


cd /root/krempo
#Install SSL Certificate using Let's Encrypt
#calls a script in krempo dir
clear
if [[ $InstallLetsEncrypt == 1 ]]
then
    chmod +x /root/setup/krempo/lamp-letsencrypt.sh
    /bin/bash /root/setup/krempo/lamp-letsencrypt.sh
fi

#automatic backups every week
clear
if [[ $InstallBackupScript == 1 ]]
then
    chmod +x /root/setup/krempo/lamp-backups.sh
    /bin/bash /root/setup/krempo/lamp-backups.sh $fulldomain $databasename $databaseusername $databaseuserpassword
fi
sleep 3

#Mod Security
if [[ $InstallModSecurity == 1 ]]
then
    chmod +x /root/setup/krempo/lamp-modsecurity2.sh
    /bin/bash /root/setup/krempo/lamp-modsecurity2.sh
fi

echo "----------------------------"
echo "We have reached the end of the script!"
echo "Visit your website $fulldomain now in a browser"
echo "Open /root/setup/krempo/logininfo.txt for your login details"
echo "----------------------------"

