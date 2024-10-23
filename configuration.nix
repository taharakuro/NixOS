{ config, lib, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Use the GRUB 2 boot loader.
  boot.loader.grub.enable = true;
  boot.loader.grub.version = 2;
  boot.loader.grub.devices = [ "/dev/sda" ];  # Укажите здесь ваш диск

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
    initialPassword = "1";  # Простой незашифрованный пароль
  };

  system.stateVersion = "24.05";
}
