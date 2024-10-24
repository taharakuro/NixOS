{ config, lib, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Use the GRUB 2 boot loader.
  boot.loader.grub.version = 2;
  boot.loader.grub.efiSupport = true;
  boot.loader.grub.device = "/dev/sda";
  boot.loader.grub.configurationLimit = 10;

  # Swap для подкачки
  swapDevices = [ { device = "/dev/sda2"; } ];

  # Btrfs root
  fileSystems."/" = {
    device = "/dev/sda3";
    fsType = "btrfs";
  };

  # EFI boot
  fileSystems."/boot" = {
    device = "/dev/sda1";
    fsType = "vfat";
  };

  networking.networkmanager.enable = true; # Easiest to use and most distros use this by default.

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Set your time zone.
  time.timeZone = "Europe/Moscow";

  # Define a user account. Don't forget to set a password with passwd. 
  users.users.tahara = {
    isNormalUser = true;
    home = "/home/tahara";
    description = "Tahara";
    shell = pkgs.bash;
    extraGroups = [ "wheel" "networkmanager" ];
    initialPassword = "1";
  };

  system.stateVersion = "24.05";
}
