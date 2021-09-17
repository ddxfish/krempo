sudo apt-get update
sudo apt-get install software-properties-common
sudo add-apt-repository universe
sudo apt-get update
sudo apt-get -y install certbot python3-certbot-apache
sudo certbot --apache
sudo certbot renew --dry-run
echo "Krempo: Please read the above output to make sure things worked."
echo "the script does not yet detect errors during SSL cert additions"
