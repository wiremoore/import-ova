#!/bin/bash

# Import an OVA and auto provision a VM

OVA_TEMPLATE=$1
EXTRACT_PATH=".import_ova_tmp"

echo -e "Extracting OVA file........."
mkdir $EXTRACT_PATH
echo $OVA_TEMPLATE
tar -xvf "${OVA_TEMPLATE}" -C $EXTRACT_PATH

echo -e "\nSetting up VM: "
read -p "VM ID: " VM_ID
read -p "VM Name: " VM_NAME
read -p "RAM (MB)[2048]: " VM_RAM
VM_RAM=${VM_RAM:-2048}
read -p "Sockets [1]: " VM_SOCK
VM_SOCK=${VM_SOCK:-1}
read -p "Cores [1]: " VM_CORES
VM_CORES=${VM_CORES:-1}
read -p "Autostart enable [0]: " VM_AUTO_START
VM_AUTO_START=${VM_AUTO_START:-0}
read -p "KVM Virtualization enable [0]: " VM_KVM
VM_KVM=${VM_KVM:-0}
read -p "Bridge for network interface [vmbr0]: " VM_BRIDGE
VM_BRIDGE=${VM_BRIDGE:-vmbr0}

qm create ${VM_ID} --autostart ${VM_AUTO_START} --cores ${VM_CORES} --kvm ${VM_KVM} --memory ${VM_RAM} --name ${VM_NAME} --sockets ${VM_SOCK} --scsihw virtio-scsi-pci --net0 virtio,bridge=${VM_BRIDGE},firewall=0

echo -e "\nThe following disk will be convert: "
cd $EXTRACT_PATH
ls -1 *.vmdk
read -p "Do you want to proceed [n]: " CONVERT_CONFIRM

if [ $CONVERT_CONFIRM = "y" ]
then
	echo -e "\nConverting disk......"
	disk_nb=0
	for disk in *.vmdk; do
		read -p "Select Controller for ${disk} [ide/sata/scsi]: " CONTROLLER
		#qemu-img convert -f vmdk -O qcow2 "${disk}" image-${disk_nb}.qcow2
		qm importdisk ${VM_ID} "${disk}" local-lvm -format qcow2
		echo "Attach disk number ${disk_nb} to the VM......"
		qm set ${VM_ID} --${CONTROLLER}${disk_nb} local-lvm:vm-${VM_ID}-disk-${disk_nb}
		disk_nb=$((disk_nb+1))
	done
else
	echo "Operations cancelled, exiting....."
fi

cd ..
rm -r $EXTRACT_PATH

