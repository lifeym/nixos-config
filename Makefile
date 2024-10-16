.PHONY: disko-nixos-%
disko-nixos-%:
	sudo nix --experimental-features "nix-command flakes" run github:nix-community/disko/latest -- --mode disko \
		hosts/nixos/$*/disko-config.nix

.PHONY: disko-install-%
disko-install-%:
	nixos-generate-config --dir hosts/nixos/red-yuanchun --no-filesystems
	rm configurations.nix # not used
	read -p "This will erase all data from devie, enter main disk device for installation to continue:" DISK_MAIN \
		&& sudo nix run 'github:nix-community/disko/latest#disko-install' -- --flake ".#$*" --disk main ${DISK_MAIN}
