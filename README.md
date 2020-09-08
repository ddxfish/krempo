To be brief, you get a new blank Ubuntu VPS and run this script on it as root to have a fully set up LAMP server, and optionally a full Wordpress install. It asks you some questions but nothing difficult.<br>
<br>
Version 2020.2<br>
Today is 9-8-2020<br>
Ubuntu is 20.04.1<br>
<br>

# krempo - automatic LAMP setup
lamp-main.sh sets up a LAMP server with Wordpress. Here is what this does:
- apt upgrade
- .bash_aliases added to both users, check the aliases
- Installs php 7.4, Apache2, mysql-server, mod_ssl
- Runs the script/wizard to secure your sql server
- ufw firewall installed, block all, open 22, 80, 443, 10099, 65420
- Changes SSH port to 65420
- Installs Webmin on port 10099

lamp-main.sh can also install Wordpress for you, but you can cancel here:
- Creates a VirtualHost for a site with http and https
- Downloads Wordpress and puts it in your website root
- Creates database for Wordpress and user with perms
- If you have a real domain, Let's Encrypt free SSL cert installs
- Creates automatic weekly backups in /root/website-backups


# Files
lamp-main.sh - You only need to run this one. Others are run by it.<br>
LAMP-modsecurity2.sh	- Mod_security install -- may prevent normal use<br>
lamp-bash-alias.sh - installs aliases to use features in this script<br>
lamp-letsencrypt.sh - installs a free SSL cert on your site<br>
lamp-backups.sh - creates a weekly backup of the site in /root/website-backups<br>


