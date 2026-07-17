nix --extra-experimental-features "nix-command flakes" run github:nix-community/disko/latest -- --mode disko ./disko.nix
nixos-generate-config --root /mnt
cp config/* /mnt/etc/nixos/
nixos-install --flake /mnt/etc/nixos#nixos
