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
		&& parted ${DISK_MAIN} -- set 3 esp on\
		&& mkfs.ext4 -L nixos ${DISK_MAIN}1\
		&& mkswap -L swap ${DISK_MAIN}2\
		&& mkfs.fat -F 32 -n boot ${DISK_MAIN}3\
		&& mount /dev/disk/by-label/nixos /mnt\
		&& mkdir -p /mnt/boot\
		&& mount -o umask=077 /dev/disk/by-label/boot /mnt/boot\
		&& swapon ${DISK_MAIN}2

.PHONY: install-%
install-nixos-%: hardware-config-nixos-%
	nixos-install --option substituters "https://mirror.sjtu.edu.cn/nix-channels/store" --flake .#$*

.PHONY: history
history:
	nix profile history --profile /nix/var/nix/profiles/system

.PHONY: repl
repl:
	nix repl -f flake:nixpkgs

.PHONY: clean
clean:
	sudo nix profile wipe-history --profile /nix/var/nix/profiles/system  --older-than 7d

.PHONY: gc
gc:
	sudo nix-collect-garbage --delete-old
