To be brief, you get a new blank Ubuntu 20.04.x VPS or bare metal with minimum 40GB storage for backups of a small site, and run this script on it as root to have a fully set up LAMP server, and optionally a full Wordpress install. It asks you some questions but nothing difficult. Get your notepad ready, you will have to make up a few passwords and keep track of them. 
<br>

# krempo - automatic LAMP setup
lamp-main.sh sets up a LAMP server with Wordpress.
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
- sudo su
- cd /root
- git clone https://github.com/ddxfish/krempo.git
- cd krempo
- chmod +x *.sh
- ./lamp-main.sh
- apt-get upgrade (automatic)
- SQL Security - Answer No to first question, Yes to the rest
- Apache security (automatic)
- UFW Firewall (automatic, see open ports)
- Change SSH to port 65420 (automatic)
- Install webmin (yes/no, only if you use it)
- Enter domain without www for virtual host (yes/no)
- Create your SQL db, user, pass (write down logins)
- Install WordPress files (write down logins)
- Set up Wordpress website (gives you login)
- Let's Encrypt free SSL cert setup (yes/no)
- Set up backups for this site? Creates weekly backup script (yes/no)
- Install mod_security2? (yes/no, can block some normal use)

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
  - saveapache - resets all permissions to /var/www to www-data
  - rapache2 - restart apache2
- Backups (requires more than 8GB storage!)
  - Makes a weekly backup of SQL and website files with timestamp
  - Rotates out backups, keeps 5 total
  - Only works for the website set up in script
  - /root/website-backups
  

# Files
lamp-main.sh - You only need to run this one. Others are run by it.<br>
lamp-modsecurity2.sh	- Mod_security install -- mild danger: may prevent normal use<br>
lamp-bash-alias.sh - installs aliases to use features in this script<br>
lamp-letsencrypt.sh - installs a free SSL cert on your site<br>
lamp-backups.sh - creates a weekly backup of the site in /root/website-backups<br>


