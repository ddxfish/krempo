Version 2020
Today is 5-23-2020
Ubuntu is 20.04

20.04 version
- Bash Aliases (lamp-bash-aliases.sh) - working



# krempo
LAMP Setup Scripts<br>
This sets up a LAMP server with Wordpress. Here is what this does:
- Updates the server
- Installs tools like vim and mlocate
- Installs php 7.2 and Apache2
- Changes SSH port to 65420
- Installs Webmin on port 42099
- Installs software firewall (port based, ufw)
- Schedules webmin and phpmyadmin to disable nightly
- Auto-setup for a new domain (www-only!!!) 
- Downloads and installs Wordpress on that domain

LAMP-modsecurity2.sh	- Mod_security install (not for regular servers)<br>
lamp-bash-alias.sh - command prompt aliases (already done in lamp-main.sh)<br>
lamp-main.sh - this is everything except mod_security<br>

