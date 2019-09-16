#!/bin/bash -x
vboxmanage () { VboxManage.exe "$@"; }
VM_NAME="VM_ACIT4640"
SED_PROGRAM='/^Config file:/ { s/^.*:\s\+\(\S\+\)/\1/; s|\\\\|/|gp }'
VM_DIR=$(dirname "$VBOX_FILE")
vboxmanage createhd --filename ../$VM_NAME.vdi --size 10240
vboxmanage createvm --name $VM_NAME --ostype "RedHat_64" --register
VBOX_FILE=$(vboxmanage showvminfo "$VM_NAME" | sed -ne "$SED_PROGRAM")
vboxmanage storagectl $VM_NAME --name "SATA Controller" --add sata --controller IntelAHCI
vboxmanage storageattach $VM_NAME --storagectl "SATA Controller" --port 0 --device 0 --type hdd --medium ../$VM_NAME.vdi
vboxmanage storagectl $VM_NAME --name "IDE Controller" --add ide
vboxmanage storageattach $VM_NAME --storagectl "IDE Controller" --port 0 --device 0 --type dvddrive --medium ../../ISO/CentOS-7-x86_64-Minimal-1810.iso
vboxmanage modifyvm $VM_NAME --cpus 1 --memory 1024 --audio none --nic1 natnetwork
