This is a set of scripts that simplifies the installation of LAMP (Linux Apache MySQL PHP) on an Ubuntu 20.04.3 LTS server. It works on bare metal or cloud servers. You run the script and it walks you through the setup. It takes about 15 minutes on a low-end cloud server.
<br>

# krempo - automatic LAMP setup
Here is what this script does exactly:
- apt upgrade
- bash aliases for convenience
- PHP 7.4, Apache2, mysql-server, mod_ssl
- Secure MySQL wizard
- ufw firewall installed, open 22, 80, 443, 10099, 65420
- Changes SSH port to 65420
- Installs phpmyadmin example.com/phpmyadmin
- (optional) Installs Webmin on port 10099
- (optional) Creates a Virtual Host for your site (supports subdomains now)
- (optional) Installs Wordpress
- (optional) Creates backup script for website and database
- (optional) Let's Encrypt SSL certificate (DNS A record required)
- (optional) Mod_security (only use if you can troubleshoot)


# Usage
Run lamp-main.sh, it installs the other scripts during the install. (optional) items give you a choice during install.
- sudo su
- cd /root
- git clone https://github.com/ddxfish/krempo.git
- cd krempo
- chmod +x *.sh
- ./lamp-main.sh
- follow the script

# Tools
After you install, you have acces to a few tools to manage your site
- phpmyadmin
  - disables itself every night for security - it just changes the directory name
  - **enablephpmyadmin** / **disablephpmyadmin** shell aliases both work to enable/disable
  - http://example.com/phpmyadmin/ for access
- Webmin
  - Disables itself every night for security - stops the service
  - **startwebmin** / **stopwebmin** is an alias to systemctl stop/start
  - https://example.com:10099 for access
- Shell Aliases
  - goweb - cd /var/www
  - duu --- du --max-depth 1   - shows directory usage
  - saveapache - resets all permissions to /var/www to www-data
  - rapache2 - restart apache2
  - enablephpmyadmin / disablephpmyadmin
  - startwebmin / stopwebmin
- Backups (make sure you have enough storage space!)
  - Makes a weekly backup of SQL and website files with timestamp
  - Rotates out backups, keeps 5 total
  - Only works for the website set up in script
  - /root/website-backups is the backup location


# Files
Just run the main file and it calls the rest. You can run letsencrypt directly, but the others have command line arguments required for them to work.
lamp-main.sh - You only need to run this one. This script calls the others.<br>
lamp-modsecurity2.sh	- Mod_security install -- mild danger: may prevent normal use<br>
lamp-bash-alias.sh - installs aliases to use features in this script<br>
lamp-letsencrypt.sh - installs a free SSL cert on your site<br>
lamp-backups.sh - (can't run directly) creates a backup script for the website<br>
lamp-wordpress.sh - (can't run directly) installs complete WordPress site with login info

# Troubleshooting
**no response from URL**
- Check your firewalls (AWS Security Groups) to ensure port 80 and 443 are open. AWS has its own firewall layered on top of our UFW setup.
- Static IP / Elastic IP needs to be set up so DNS matches the IP

**Cant login to SSH or SFTP**
- We changed the port to 65420 instead of 22
- Check firewall on your cloud provider, or port forwarding if applicable

**Webmin not working**
- This will shut down every 24 hours for security. **startwebmin** shell alias will start webmin.
- Reset root password if you are using root user
- Try https://www.yourdomain.com:10099

**phpmyadmin not working**
- This shuts down every 24 hours for security. Shell alias **enablephpmyadmin** will enable phpmyadmin
- Login to your database using your db user and pass we created in krempo

# AWS Setup
If you are on AWS EC2 then you just spin up a new instance with at least 1GB memory and 40GB storage volume. Get more memory and storage if you can. Use Ubuntu 20.04.3 LTS with x86/x64. Edit your security group to allow ports 22, 80, 443, 10099, 65420 from addresses 0.0.0.0/0 - if you have tech knowledge, only allow your own IP for 22, 10099 and 65420. Save your private key at the end and connect using SSH. Create an Elastic IP in AWS console and attach it to your instance. If you are on Linux, use the shell or Remmina to connect. If you are on Windows you use Puttygen to convert to a putty private key, then use putty to connect to your server with that private key, ubuntu@123.123.123.123 on port 22. Replace with your AWS elastic IP.  

# Next Steps
- Automate entirely by passing in arguments
