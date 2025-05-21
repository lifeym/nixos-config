# My nixos-config

## Directory Structure

1. outputs: All nixosConfigurations/darwinConfiguraions outputs goes here, follows "outputs/system/hostName" rule, resolves "how to build the system".
2. modules: All importable modules placed here.
3. lib: Utility function library.
4. hosts: All nixosConfiguration/darwinConfiguraion of the host placed here, follows "hosts/hostName" resolves "how the system will be after built".
5. standalone: All hosts which cannot install nixos, and only use nix package manager, they must have seperate flake.nix

## How to add a new host?
1. Create a folder under "hosts", the name of folder is "host name"
2. Place configuration.nix under the "host name folder", and rename to "default.nix", so we can import it automaticly.
3. Copy hardware-configuration.nix to the "host name folder" too.
4. Create a folder which name equals step 1's under outputs/nixos/"system"/ (or outputs/darwin/"system/" if use macos), which "system" is the system of host.
5. Follow other host's file contents as sample.
