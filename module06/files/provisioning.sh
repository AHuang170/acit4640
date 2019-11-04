#!/bin/bash -x

#Firewall configuration
setup_firewall(){
	firewall-cmd --zone=public --add-service=http
	firewall-cmd --zone=public --add-service=https
	firewall-cmd --zone=public --add-service=ssh
	firewall-cmd --zone=public --remove-service=dhcpv6-client
	firewall-cmd --zone=public --add-port=80/tcp
	firewall-cmd --zone=public --add-port=443/tcp
	firewall-cmd --zone=public --add-port=22/tcp
	firewall-cmd --runtime-to-permanent
}

#Disable SELinux and apply change to current session
disable_selinux(){
	setenforce 0
	sed -r -i 's/SELINUX=(enforcing|disabled)/SELINUX=permissive/' /etc/selinux/config
}

#Setup Web service
create_todoapp_user(){
	useradd -m -r todo-app && passwd -l todo-app
}

#Install web service packages
install_web_packages(){
	systemctl enable mongod && systemctl start mongod
}


#Applcation Setup
configure_web_packages(){
	cp /home/admin/database.js /home/todo-app/database.js
	cd /home/todo-app
	#sudo -u todo-app -H sh -c "
	su - todo-app bash -c "
		mkdir /home/todo-app/app;
		git clone https://github.com/timoguic/ACIT4640-todo-app.git /home/todo-app/app;
		cd /home/todo-app/app;
		npm install;
		mv /home/todo-app/database.js /home/todo-app/app/config/database.js;
	"
	chmod -R 755 /home/todo-app
}

#Production application setup
install_nginx(){
	systemctl enable nginx && systemctl start nginx
	cp /home/admin/nginx.conf /etc/nginx/nginx.conf
	nginx -s reload
}

#Run NodeJS as daemon
create_todoapp_daemon(){
	cp /home/admin/todoapp.service /lib/systemd/system/todoapp.service
	systemctl daemon-reload
	systemctl enable todoapp && systemctl start todoapp
}

set -u

setup_firewall

disable_selinux

#Skipping guest addition setup

create_todoapp_user

install_web_packages

configure_web_packages

install_nginx

create_todoapp_daemon
