nix --experimental-features "nix-command flakes" run github:nix-community/disko/latest -- --mode disko ./disko.nix
nixos-generate-config --root /mnt
cp configuration.nix /mnt/etc/nixos/configuration.nix
