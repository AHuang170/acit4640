#!/bin/bash -x

#Script to be ran at the user's home directory ~, assumes directory /setup to be in the root diretory as well.
#VM .vdi file to be created at windows directory D:/VM_Folder

set -u

VM_NAME="VM_ACIT4640"

vboxmanage () { /mnt/c/Program\ Files/Oracle/VirtualBox/VboxManage.exe "$@";}

setup_host_network () {
	echo "Setting up the NAT network."
	vboxmanage natnetwork add --netname net_4640 --network "192.168.250.0/24" --enable --dhcp off --ipv6 off
	vboxmanage natnetwork modify --netname net_4640 --port-forward-4 "ssh:tcp:[]:50022:[192.168.250.10]:22"
	vboxmanage natnetwork modify --netname net_4640 --port-forward-4 "http:tcp:[]:50080:[192.168.250.10]:80"
	vboxmanage natnetwork modify --netname net_4640 --port-forward-4 "https:tcp:[]:50443:[192.168.250.10]:443"
	vboxmanage natnetwork modify --netname net_4640 --port-forward-4 "pxe:tcp:[]:50222:[192.168.250.200]:22"
	vboxmanage natnetwork start --netname net_4640
	echo "Host network created."
}

setup_system () {
	echo "Creating new VM"
	VM_FOLDER="C:/VM_Folder"
	vboxmanage createvm --name $VM_NAME --ostype "RedHat_64" --register --basefolder $VM_FOLDER
	SED_PROGRAM="/^Config file:/ { s/^.*:\s\+\(\S\+\)/\1/; s|\\\\|/|gp }"
	VBOX_FILE=$(vboxmanage showvminfo "$VM_NAME" | sed -ne "$SED_PROGRAM")
	VM_DIR=$(dirname "$VBOX_FILE")
	VM_PATH="${VM_FOLDER}/${VM_NAME}"
	vboxmanage createmedium --filename $VM_PATH.vdi --size 10240 --format VDI
	vboxmanage storagectl $VM_NAME --name "SATA Controller" --add SATA --controller IntelAHCI
	vboxmanage storageattach $VM_NAME --storagectl "SATA Controller" --port 0 --device 0 --type hdd --medium $VM_PATH.vdi
	#Not attaching ISO file as we are installing OS from PXE serve
	vboxmanage modifyvm $VM_NAME --cpus 1 --memory 2048 --audio none --nic1 natnetwork --nat-network1 net_4640 --boot1 disk --boot2 net
	echo "VM created."
}

start_pxe_server () {
	#Assumption: Based on given description, the PXE server VM is already imported from the .ova file as the VM named PXE_4640, starts off not powered on
	#Assumption: This script and the resource directory /setup will be in the same directory as well

	PXE_NAME="PXE_4640"
	SETUP_DIR="./setup"

	chmod 600 $SETUP_DIR/acit_admin_id_rsa

	vboxmanage modifyvm $PXE_NAME --nic1 natnetwork --nat-network1 net_4640
	vboxmanage startvm $PXE_NAME --type headless

	echo "Waiting for PXE server to finish booting..."

	while /bin/true; do
        	ssh -i $SETUP_DIR/acit_admin_id_rsa -p 50222 -o ConnectTimeout=2s -o StrictHostKeyChecking=no -q admin@localhost exit
        	if [ $? -ne 0 ]; then
			sleep 2s
        	else
                	break
        	fi
	done

	echo "PXE server started and services running"
}

send_kickstart_file () {

	echo "Sending kickstart and configuration files"

	scp -r -P 50222 -i $SETUP_DIR/acit_admin_id_rsa $SETUP_DIR admin@localhost:/home/admin/
	ssh -i $SETUP_DIR/acit_admin_id_rsa -p 50222 -o ConnectTimeout=2s -o StrictHostkeyChecking=no -q admin@localhost "sudo chmod 755 /home/admin/setup/ks.cfg"
	ssh -i $SETUP_DIR/acit_admin_id_rsa -p 50222 -o ConnectTimeout=2s -o StrictHostKeyChecking=no -q admin@localhost "sudo mv /home/admin/setup/ks.cfg /var/www/lighttpd/ks.cfg"
	ssh -i $SETUP_DIR/acit_admin_id_rsa -p 50222 -o ConnectTimeout=2s -o StrictHostKeyChecking=no -q admin@localhost "sudo rm /home/admin/setup/acit_admin_id_rsa"
	ssh -i $SETUP_DIR/acit_admin_id_rsa -p 50222 -o ConnectTimeout=2s -o StrictHostKeyChecking=no -q admin@localhost "sudo mv /home/admin/setup /var/www/lighttpd/setup"
}

echo "Installing new VM."

setup_host_network
setup_system
start_pxe_server
send_kickstart_file

vboxmanage startvm $VM_NAME

echo "OS installation started"
