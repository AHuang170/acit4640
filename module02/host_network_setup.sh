#!/bin/bash -x
echo "Setting up VM NAT network"
vboxmanage () { VboxManage.exe "$@"; }
vboxmanage natnetwork add --netname net_4640 --network "192.168.250.0/24" --enable --dhcp off --ipv6 off
vboxmanage natnetwork modify --netname net_4640 --port-forward-4 "ssh:tcp:[]:50022:[192.168.250.10]:22"
vboxmanage natnetwork modify --netname net_4640 --port-forward-4 "http:tcp:[]:50080:[192.168.250.10]:80"
vboxmanage natnetwork modify --netname net_4640 --port-forward-4 "https:tcp:[]:50443:[192.168.250.10]:443"
vboxmanage natnetwork start --netname net_4640
echo "DONE!"
