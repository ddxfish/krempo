#!/bin/bash
#script to back up SQL and files for website
#Version 2020.1
#Today is: 6-2-2020
#Ubuntu is 20.04 LTS

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
echo "You only need to do this once"
echo Give your website backup files a friendly name without spaces
read websitename
echo Input the full path to your website root directory without trailing slash /
read websitepath
echo Input database name:
read databasename
echo Input database username:
read databaseusername
echo Input database user password
read databaseuserpassword
echo ----------Creating backup script------------

echo "
rm -fr old4
mkdir current
mkdir old1
mkdir old2
mkdir old3
mkdir old4

mv old3 old4
mv old2 old3
mv old1 old2
mv current old1

mkdir current

tar czf current/$websitename.tgz $websitepath/*
mysqldump -u $databaseusername -p$databaseuserpassword $databasename > current/$databasename.sql
touch current/`date +%F--%T`
" | tee /root/website-backups/backup.sh

chmod +x /root/website-backups/backup.sh

#crontab this weekly Sunday night
(crontab -l ; echo "0 23 * * 0 /bin/sh /root/website-backups/backup.sh") | sort - | uniq - | crontab -

