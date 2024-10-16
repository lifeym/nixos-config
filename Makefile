.PHONY: hardware-config-nixos-%
hardware-config-nixos-%:
	[ -d hosts/nixos/$* ] && nixos-generate-config --dir hosts/nixos/$*
	-@rm hosts/nixos/$*/configuration.nix # not used

DISK_MAIN := /dev/sda

.PHONY: disko-install-nixos-%
disk-red-yuanchun:
	read -p "This will erase all data from devie `${DISK_MAIN}`, press any key then <Enter> to continue, <C+c> to stop:"\
		&& sudo parted ${DISK_MAIN} -- mklabel gpt\
		&& sudo parted ${DISK_MAIN} -- mkpart root ext4 512MB -8GB\
		&& sudo parted ${DISK_MAIN} -- mkpart swap linux-swap -8GB 100%\
		&& sudo parted ${DISK_MAIN} -- mkpart ESP fat32 1MB 512MB\
		&& sudo parted ${DISK_MAIN} -- set 3 esp on\
		&& sudo mkfs.ext4 -L nixos ${DISK_MAIN}\
		&& sudo mkswap -L swap /dev/sda2\
		&& sudo mkfs.fat -F 32 -n boot /dev/sda3\
		&& sudo mount /dev/disk/by-label/nixos /mnt\
		&& sudo mkdir -p /mnt/boot\
		&& sudo mount -o umask=077 /dev/disk/by-label/boot /mnt/boot\
		&& sudo swapon /dev/sda2
