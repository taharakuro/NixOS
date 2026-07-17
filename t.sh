nix --extra-experimental-features "nix-command flakes" run github:nix-community/disko/latest -- --mode disko config/disko.nix
nixos-generate-config --root /mnt
cp config/* /mnt/etc/nixos/
nix --extra-experimental-features "nix-command flakes" flake lock /mnt/etc/nixos
nixos-install --flake /mnt/etc/nixos#nixos