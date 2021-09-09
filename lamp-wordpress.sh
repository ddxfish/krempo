#!/bin/bash
#installs Wordpress as part of krempo script
#Version 2021.2
#Today is: 9-8-2021
#Ubuntu is 20.04.3 LTS
#
#params: lamp-wordpress.sh $1 $2 $3 $4 $5 $6
#params: lamp-wordpress.sh $websitename $subdomain $websitedir $databasename $databaseusername $databaseuserpassword $fulldomain
#Wordpress files
cd /var/www/$1/$2
rm latest.tar.gz
rm -fr wordpress
wget https://wordpress.org/latest.tar.gz
tar xf latest.tar.gz
mv -f /var/www/$1/$2/wordpress/* $3
chown -R www-data:www-data /var/www
rm latest.tar.gz
rm -fr wordpress

clear
echo Get your root password ready.
echo This will ask for your root password thrice.
echo 1- Create DB, 2- Create User, 3- Grant
echo Go ahead with your root pass three times:

#create database with info given
mysql -u root -p -e "CREATE DATABASE $4"
mysql -u root -p -e "CREATE USER '$5'@'localhost' IDENTIFIED BY '$6';"
mysql -u root -p -D $4 -e "GRANT ALL ON $4.* TO '$5'@'localhost';"

#install wordpress CLI tool
curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
chmod +x wp-cli.phar
sudo mv wp-cli.phar /usr/local/bin/wp

clear
cd $3
#install wordpress with random password
wordpresspass=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 16 | head -n 1`
#create config
wp config create --allow-root --dbname=$4 --dbuser=$5 --dbpass=$6
#create DB -- might fail due to already created, thats okay
#wp db create --allow-root
#echo "Krempo: Errors are okay if they say database already exists"
#install the core
wp core install --allow-root --url=$7 --title=$1 --admin_user=supervisor --admin_password=$wordpresspass --admin_email=info@$1
sleep 3

#MAKE SURE USER TAKES THE LOGIN INFO
echo Copy your Wordpress login information:
echo -----------------------------------
echo host: http://$7/wp-admin/
echo user: supervisor
echo pass: $wordpresspass
read nothing
echo Are you really sure you got that? Its important.
read nothing
