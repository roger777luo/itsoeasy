#!/bin/sh
env_build () {
    yum install epel-release -y
    yum install -y python-setuptools m2crypto supervisor
    yum install net-tools -y
    easy_install pip
    pip install shadowsocks
}

# set password
password=$1
server_port=$2
local_port=$3
timeout=600
method="aes-256-cfb"

env_build

cp shadowsocks.json target.json
sed -i "s/#password/${password}/g" target.json
sed -i "s/#server_port/${server_port}/g" target.json
sed -i "s/#local_port/${local_port}/g" target.json

cp target.json /etc/shadowsocks.json

num=$(grep shadowsocks /etc/supervisord.conf | grep -v grep | wc -l)

if [ $num -eq 0 ];then
echo -e "\n[program:shadowsocks]
command=ssserver -c /etc/shadowsocks.json
autostart=true
autorestart=true
user=root
log_stderr=true
logfile=/var/log/shadowsocks.log" >> /etc/supervisord.conf
fi

num=$(grep supervisord /etc/rc.local | grep -v grep | wc -l)
if [ $num -eq 0 ];then
echo -e "\nsytemctl start supervisord.service" >> /etc/rc.local
fi

systemctl start firewalld.service 

systemctl stop supervisord.service

firewall-cmd --zone=public --add-port=${server_port}/tcp --permanent

firewall-cmd --reload

systemctl start supervisord.service

sleep 1

num=$(netstat -anplt |grep ${server_port} | grep -v grep | wc -l)
if [ ${num} -eq 0 ];then
    echo "not found port:${server_port} "
else
    echo "done"
fi