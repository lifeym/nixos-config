.PHONY: hardware-config-nixos-%
hardware-config-nixos-%:
	[ -d hosts/nixos/$* ] && nixos-generate-config --dir hosts/nixos/$*
	-@rm hosts/nixos/$*/configuration.nix # not used

DISK_MAIN := /dev/sda

.PHONY: disk-red-yuanchun
disk-red-yuanchun:
	parted ${DISK_MAIN} -- mklabel gpt\
		&& parted ${DISK_MAIN} -- mkpart root ext4 512MB -8GB\
		&& parted ${DISK_MAIN} -- mkpart swap linux-swap -8GB 100%\
		&& parted ${DISK_MAIN} -- mkpart ESP fat32 1MB 512MB\
		&& sudo parted ${DISK_MAIN} -- set 3 esp on\
		&& sudo mkfs.ext4 -L nixos ${DISK_MAIN}1\
		&& sudo mkswap -L swap ${DISK_MAIN}2\
		&& sudo mkfs.fat -F 32 -n boot ${DISK_MAIN}3\
		&& sudo mount /dev/disk/by-label/nixos /mnt\
		&& sudo mkdir -p /mnt/boot\
		&& sudo mount -o umask=077 /dev/disk/by-label/boot /mnt/boot\
		&& sudo swapon ${DISK_MAIN}2

.PHONY: install-%
install-%:
	nix-install --option substituters "https://mirror.sjtu.edu.cn/nix-channels/store" --flake .#$*
