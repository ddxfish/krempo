#Install ModSecurity2 on Apache2
#Today is 2020-2-16


#run it as root!!!
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

#Install
apt-get update
apt-get install libapache2-mod-security2 git
service apache2 restart

#Basic security conf
cp /etc/modsecurity/modsecurity.conf-recommended /etc/modsecurity/modsecurity.conf
sed -i 's/SecRuleEngine DetectionOnly/SecRuleEngine On/g' /etc/modsecurity/modsecurity.conf
service apache2 restart

#Remove current ruleset (backup to .old)
mv /usr/share/modsecurity-crs /usr/share/modsecurity-crs.old

#Clone latest OWASP ruleset and install example config
git clone https://github.com/SpiderLabs/owasp-modsecurity-crs.git /usr/share/modsecurity-crs
cp /usr/share/modsecurity-crs/crs-setup.conf.example /usr/share/modsecurity-crs/crs-setup.conf

#Doesn't work, stopped here
perl -0777 -i.original -pe 's#</IfModule>#\tIncludeOptional /usr/share/modsecurity-crs/*.conf\n\tIncludeOptional /usr/share/modsecurity-crs/rules/*.conf\n</IfModule>#igs' /etc/apache2/mods-enabled/security2.conf
