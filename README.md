To be brief, you get a new blank Ubuntu 20.04.1 VPS and run this script on it as root to have a fully set up LAMP server, and optionally a full Wordpress install. It asks you some questions but nothing difficult. Get your notepad ready, you will have to make up a few passwords and keep track of them.
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

# Install using lamp-main.sh
- Download the .tar or .zip
- Unzip on your server to /root/krempo
- chmod +x *.sh
- ./lamp-main.sh

# Tools
After you install, you have acces to a few tools to help you
- phpmyadmin
  - disables itself every night for security - it just changes the directory name
  - **enablephpmyadmin** / **disablephpmyadmin** aliases both work to enable it
  - http://example.com/phpmyadmin/ for access
- Webmin
  - Disables itself every night for security - stops the service
  - **startwebmin** / **stopwebmin** is an alias to systemctl stop/start
  - https://example.com:10099 for access (reset your root pass first!)
- Aliases
  - goweb - cd /var/www
  - duu --- du --max-depth 1   - shows directory usage
  - saveapache - resets all permissions to www-data user
  - rapache2 - restart apache2
- Backups (requires more than 8GB storage!)
  - Makes a weekly backup of SQL and website files with timestamp
  - Rotates out backups, keeps 5 total
  - Only works for the website set up in script
  - /root/website-backups
  
  

# Files
lamp-main.sh - You only need to run this one. Others are run by it.<br>
LAMP-modsecurity2.sh	- Mod_security install -- may prevent normal use<br>
lamp-bash-alias.sh - installs aliases to use features in this script<br>
lamp-letsencrypt.sh - installs a free SSL cert on your site<br>
lamp-backups.sh - creates a weekly backup of the site in /root/website-backups<br>


