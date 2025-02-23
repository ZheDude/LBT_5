sudo apt install bind9
sudo apt install dnsutils


sudo nano /etc/bind/named.conf.options


forwarders {
    1.2.3.4;
    5.6.7.8;
};





sudo systemctl start bind9.service
sudo systemctl enable bind9.service










### CHAT GPT WANDLE DAS IN EIN SCRIPT UM