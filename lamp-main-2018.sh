#!/bin/bash
#script to set up aws as a web server.
#Version 0.3
#Today is: 2-15-2020


#run it as root!!!
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

echo This will install LAMP.
echo Press Ctrl + C to cancel or ENTER to continue
read nothing

#get server IP
mkdir /root/setup
cd /root/setup
rm -f ip.php*
wget http://www.etcwiki.org/ip.php
serverip=`cat ip.php`

#Add this stuff for bash aliases
echo "#overrides
alias ls='ls -lA --group-directories-first --color'
alias vi='vim'
alias duu='du -ch --max-depth=1 .'

alias editalias='vim /root/.bash_aliases'
alias sourcealias='source ~/.bash_aliases'

#LAMP stuff
alias eapache2='vim /etc/apache2/apache2.conf'
alias rapache2='systemctl reload apache2.service'
alias saveapache='chown -R www-data:www-data /var/www'
alias vlapache='tail -n 50 /var/log/apache2/error.log'

#Webmin and phpmyadmin
alias disablephpmyadmin='mv -f /usr/share/phpmyadmin /usr/share/phpmyadminx'
alias enablephpmyadmin='mv -f /usr/share/phpmyadminx /usr/share/phpmyadmin'
alias stopwebmin='systemctl stop webmin'
alias startwebmin='systemctl start webmin'

#Going places
alias goho='cd /home/ubuntu'
alias goro='cd /root'
alias goweb='cd /var/www'
alias goapache='cd /etc/apache2/sites-available'

LS_COLORS=\$LS_COLORS:'di=0;35:'
export LS_COLORS
export PS1='\[\e[31m\]\u\[\e[m\]\[\e[36m\]@\[\e[m\]\[\e[32m\]\h\[\e[m\] \[\e[35m\]\w\[\e[m\] \[\e[34m\]\\\\$\[\e[m\] '
export EDITOR=/usr/bin/vim" | tee /root/.bash_aliases /home/ubuntu/.bash_aliases


#important stuff
#sudo passwd
apt-get update
apt-get -y install elinks vim mlocate
updatedb

#sql (requires user input and root pass, not unattended)
apt-get -y install mysql-server mysql-client
mysql_secure_installation

#apache
apt-get -y install apache2


#Change default server and directory
#/var/www/default/html
mkdir -p /var/www/default/html
mv /var/www/html/* /var/www/default/html
sed -i 's#/var/www/html#/var/www/default/html#g' /etc/apache2/sites-available/000-default.conf
rm -fr /var/www/html
systemctl restart apache2


#php 7.2
apt-get -y install php7.2 libapache2-mod-php7.2 php7.2-mysql php7.2-curl php7.2-gd php-imagick php-memcache php7.2-xmlrpc php7.2-mbstring php7.2-xml
sed -i 's/max_execution_time = 30/max_execution_time = 60/g' /etc/php/7.2/apache2/php.ini
sed -i 's/memory_limit = 128M/memory_limit = 348M/g' /etc/php/7.2/apache2/php.ini
sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 16M/g' /etc/php/7.2/apache2/php.ini
systemctl restart apache2


#opcache - might not be that important
apt-get -y install php7.2-opcache php-apcu
systemctl restart apache2

#install ssl
a2enmod ssl
a2ensite default-ssl
systemctl restart apache2

#Enable Apache modules
a2enmod rewrite
systemctl restart apache2

#set up ufw
apt-get -y install ufw
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp 
ufw allow 42099/tcp
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

#Security for Apache
sed -i 's/ServerTokens OS/ServerTokens Prod/g' /etc/apache2/conf-available/security.conf
sed -i 's/ServerSignature On/ServerSignature Off/g' /etc/apache2/conf-available/security.conf
#Disallow indexes by default, denied ACCESS TO var/www
perl -0777 -i.original -pe 's#<Directory /var/www/>\n\tOptions Indexes FollowSymLinks\n\tAllowOverride None\n\tRequire all granted#<Directory /var/www/>\n\tOptions -Indexes +FollowSymLinks\n\tAllowOverride None\n\tRequire all denied#igs' /etc/apache2/apache2.conf
perl -0777 -i.original -pe 's#<Directory />\n\tOptions FollowSymLinks#<Directory />\n\tOptions None#igs' /etc/apache2/apache2.conf
diff /etc/apache2/apache2.conf{,.original}

#security for php7.2
###################disable_functions popen exec shell_exec





#Mod_security
#apt-get -y install libapache2-mod-security2
#a2enmod security2
#systemctl restart apache2

#OWASP Rules??? no
#https://www.linode.com/docs/web-servers/apache-tips-and-tricks/configure-modsecurity-on-apache/

#set up phpmyadmin -create password for phpmyadmin user
apt-get install -y phpmyadmin


#set up webmin using apt
echo deb https://download.webmin.com/download/repository sarge contrib >> /etc/apt/sources.list
cd /root/setup
wget http://www.webmin.com/jcameron-key.asc
apt-key add jcameron-key.asc
apt-get update
apt-get -y install perl libnet-ssleay-perl openssl libauthen-pam-perl libpam-runtime libio-pty-perl apt-show-versions python
apt-get -y install webmin
sed -i 's#10000#42099#g' /etc/webmin/miniserv.conf
systemctl restart webmin

#make Crontab entries
(crontab -l ; echo "0 23 * * * systemctl stop webmin") | sort - | uniq - | crontab -
(crontab -l ; echo "0 23 * * * mv /usr/share/phpmyadmin /usr/share/phpmyadminx") | sort - | uniq - | crontab -

#Set up Virtual Host and root dir for a site
echo ---------------------------------------------------
echo "If you want to set up your own VirtualHosts and folders, Ctrl+C -- this will at least be a good example"
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
