#!/bin/bash -x
set -u

echo "Starting VM App setup"

#Following script to be ran as root in VM

#Initial setup
echo "Installing SSH Key"

echo "Creating admin user"
useradd -p $(openssl passwd -1 P@ssw0rd) admin
usermod -aG wheel admin
mkdir -p /home/admin/.ssh/authorized_keys
cp ~/setup/acit_admin_id_rsa.pub /home/admin/.ssh/authorized_keys/acit_admin_id_rsa.pub

echo "Installing and updating basic tools"
yum -y install epel-release vim git tcpdump curl net-tools bzip2
yum -y update

#Firewall configuration and disable SELinux
echo "Setting firewall rules"
firewall-cmd --zone=public --add-service=http
firewall-cmd --zone=public --add-service=https
firewall-cmd --zone=public --add-service=ssh
firewall-cmd --zone=public --add-port=80/tcp
firewall-cmd --zone=public --add-port=443/tcp
firewall-cmd --zone=public --add-port=22/tcp
firewall-cmd--runtime-to-permanent

echo "Disabling SELinux"
setenforce 0
sed -r -i 's/SELINUX=(enforcing|disabled)/SELINUX=permissive/' /etc/selinux/config

#Skipping VirtualBox Addition
echo "SKipping guest addition installation"

#Setup Web service
echo "Creating service user"
useradd -m -r todo-app && passwd -l todo-app

echo "Installing and enabling packages"
yum -y install nodejs npm
yum -y install mongodb-server
systemctl enable mongod && systemctl start mongod

#Applcation Setup
echo "Setup Packages"
cp ~/setup/database.js /home/todo-app/database.js
cd /home/todo-app
sudo -u todo-app -H sh -c "
mkdir app;
cd app;
git clone https://github.com/timoguic/ACIT4640-todo-app.git .
npm install
mv /home/todo-app/database.js /home/todo-app/app/config/database.js
"
cd ~

#Production application setup
echo "Installing nginx"
yum -y install nginx
systemctl enable nginx && systemctl start nginx
cp ~/setup/nginx.conf /etc/nginx/nginx.conf
nginx -s reload

#Run NodeJS as daemon
echo"Configuring deamon"
cp ~/setup/todoapp.service /lib/systemd/system/todoapp.service
systemctl daemon-reload
systemctl enable todoapp
systemctl start todoapp

echo "Done"
