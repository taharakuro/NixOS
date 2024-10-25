{ config, lib, pkgs, ... }:

{
  imports = 
    [ 
      # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Use the systemd-boot boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Install Hyprland and other system packages
  environment.systemPackages = with pkgs; [
    kitty
    firefox
  ];

  # Enable Hyprland
  programs.hyprland.enable = true;

  # Enable X server and display manager (GDM)
  services.xserver.enable = true;
  services.xserver.displayManager.gdm.enable = true;

  # Enable NetworkManager for networking
  networking.networkmanager.enable = true;

  # Enable experimental features for Nix
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Set your time zone
  time.timeZone = "Europe/Moscow";

  # Define a user account with initial password (change it later)
  users.users.tahara = {
    isNormalUser = true;
    home = "/home/tahara";
    description = "Tahara";
    shell = pkgs.bash;
    extraGroups = [ "wheel" "networkmanager" ];
    initialPassword = "1"; # Don't forget to change this password later!
  };

  # Define the state version of NixOS
  system.stateVersion = "24.05";
}
