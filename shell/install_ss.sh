#!/bin/sh
env_build () {
    yum install epel-release -y
    yum install -y python-setuptools m2crypto supervisor
    yum install net-tools -y
    easy_install pip
    pip install shadowsocks -y
}

# set password
password=$1
server_port=$2
local_port=$3
timeout=600
method="aes-256-cfb"

env_build

cp shadowsocks.json target.json
sed -i 's/#password/${password}/g' target.json
sed -i 's/#server_port/${server_port}/g' target.json
sed -i 's/#local_port/${local_port}/g' target.json

cp target.json /etc/shadowsocks.json

echo -e "\n[program:shadowsocks]
command=ssserver -c /etc/shadowsocks.json
autostart=true
autorestart=true
user=root
log_stderr=true
logfile=/var/log/shadowsocks.log" >> /etc/supervisord.conf

echo -e "\nservice supervisord start|sytemctl start supervisord.service" >> /etc/rc.local

systemctl stop supervisord.service

firewall-cmd --zone=public --add-port=${server_port}/tcp --permanent

firewall-cmd --reload

echo "done"