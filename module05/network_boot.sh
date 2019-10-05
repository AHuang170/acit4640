#!/bin/bash -x
set -u

vboxmanage () { /mnt/c/Program\ Files/Oracle/VirtualBox/VboxManage.exe "$@";}
#vboxmanage () { VboxManage.exe "$@"; }

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
	VM_NAME="VM_ACIT4640"
	SED_PROGRAM='/^Config file:/ { s/^.*:\s\+\(\S\+\)/\1/; s|\\\\|/|gp }'
	vboxmanage createvm --name $VM_NAME --ostype "RedHat_64" --register
	VBOX_FILE=$(vboxmanage showvminfo "$VM_NAME" | sed -ne "$SED_PROGRAM")
	VM_DIR=$(dirname "$VBOX_FILE")
	vboxmanage createhd --filename $VM_DIR/$VM_NAME.vdi --size 10240
	vboxmanage storagectl $VM_NAME --name "SATA Controller" --add sata --controller IntelAHCI
	vboxmanage storageattach $VM_NAME --storagectl "SATA Controller" --port 0 --device 0 --type hdd --medium $VM_DIR/$VM_NAME.vdi
	vboxmanage storagectl $VM_NAME --name "IDE Controller" --add ide
	#vboxmanage storageattach $VM_NAME --storagectl "IDE Controller" --port 0 --device 0 --type dvddrive --medium /Users/Aldrich/Desktop/ACIT_4640/ISO/CentOS-7-x86_64-Minimal-1810.iso
	vboxmanage modifyvm $VM_NAME --cpus 1 --memory 1024 --audio none --nic1 natnetwork --nat-network1 net_4640 --boot1 net
	echo "VM created."
}

start_pxe_server () {
	#Assumption: Based on given description, the PXE server VM is already imported from the .ova file as the VM named PXE_4640

	PXE_NAME="PXE_4640"
	SETUP_DIR="./setup"

	vboxmanage modifyvm $PXE_NAME --nic1 natnetwork --nat-network1 net_4640
	vboxmanage startvm $PXE_NAME --type headless

	echo "Pausing for a bit"
	sleep 30s
	echo "PXE server started and services running"
}

send_kickstart_file () {

	echo "Sending kickstart file"
	scp -P 50222 -i ~/.ssh/acit_admin_id_rsa ./setup/ks.cfg admin@localhost:~

}

echo "Installing new VM."

setup_host_network
setup_system
start_pxe_server
send_kickstart_file

echo "DONE!"
