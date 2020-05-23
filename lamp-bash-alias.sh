#!/bin/bash


#run it as root!!!
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi


#Add this stuff for bash aliases
echo "#overrides
alias ls='ls -lA --group-directories-first --color'
alias vi='vim'
alias duu='du -ch --max-depth=1 .'
alias editalias='vim /root/.bash_aliases'
alias sourcealias='source ~/.bash_aliases'
#LAMP stuff
alias eapache2='vim /etc/apache2/apache2.conf'
alias rapache2='systemctl restart apache2.service'
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
