{ config, lib, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Use the GRUB 2 boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Install Hyprland
  environment.systemPackages = with pkgs; [
    hyprland
    wayland
    kitty
    firefox
  ];

  # Включение службы для запуска Hyprland
  services.xserver.enable = true;
  services.xserver.displayManager.lightdm.enable = true; # LightDM
  services.xserver.windowManager.hyprland.enable = true;
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
