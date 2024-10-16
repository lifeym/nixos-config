.PHONY: disko-nixos-%
disko-nixos-%:
	sudo nix --experimental-features "nix-command flakes" run github:nix-community/disko/latest -- --mode disko \
		hosts/nixos/$*/disko-config.nix

.PHONY: hardware-config-nixos-%
hardware-config-nixos-%:
	[ -d hosts/nixos/$* ] && nixos-generate-config --dir hosts/nixos/$* --no-filesystems
	-@rm hosts/nixos/$*/configuration.nix # not used

.PHONY: disko-install-nixos-%
disko-install-nixos-%: hardware-config
	read -p "This will erase all data from devie, enter main disk device for installation to continue:" DISK_MAIN \
		&& sudo nix run 'github:nix-community/disko/latest#disko-install' -- --flake ".#$*" --disk main ${DISK_MAIN}
