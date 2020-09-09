#!/bin/bash
#script to back up SQL and files for website
#Version 2020.2
#Today is: 9-8-2020
#Ubuntu is 20.04.1 LTS
#
#params: lamp-backups.sh $websitename $databasename $databaseusername $databaseuserpassword

#run it as root!!!
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

#No double installs
if [[ -f "/root/website-backups/backup.sh" ]]; then
   echo "/root/website-backups/backup.sh already exists. Remove old backup setup to install again" 
   exit 1
fi

cd ~
mkdir -p /root/website-backups
cd /root/website-backups

clear
echo "We are enabling weekly backups that rotate in /root/website-backups"
echo "You only need to run this setup once"
echo ----------Creating backup script------------
pause 3
echo "
cd /root/website-backups
rm -fr old4
mkdir current
mkdir old1
mkdir old2
mkdir old3

mv old3 old4
mv old2 old3
mv old1 old2
mv current old1

mkdir current

websitepath = "/var/www/$1/html"

tar czf current/$1.tgz $websitepath/*
mysqldump -u $3 -p$4 $2 > current/$2.sql
touch current/`date +%F--%T`
" | tee /root/website-backups/backup.sh

chmod +x /root/website-backups/backup.sh

#crontab this weekly Sunday night
(crontab -l ; echo "0 23 * * 0 /bin/sh /root/website-backups/backup.sh") | sort - | uniq - | crontab -

