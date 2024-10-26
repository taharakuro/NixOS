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
    btop
    bun
    pipewire
    libgtop
    bluez
    bluez-tools
    grimblast
    gpu-screen-recorder
    hyprpicker
    btop
    matugen
    wl-clipboard
    swww
    dart-sass
    brightnessctl
    gnome.gnome-bluetooth
    python3
    gpustat
    pywal
    power-profiles-daemon
    gnome.nautilus
    nwg-look
    fwupd
    fwupd-efi
  ];

  fonts.packages = with pkgs; [
    (nerdfonts.override { fonts = [ "JetBrainsMono"  ]; })
  ];

  hardware.bluetooth.enable = true;

  services.pipewire = {
    enable = true;
    audio.enable = true;
    pulse.enable = true;
    alsa = {
      enable = true;
      support32Bit = true;
    };
    jack.enable = true;
  };

  # Enable Hyprland (and add GDM for display management)
  services.xserver = {
    enable = true;
    displayManager.gdm.enable = true;  # Включаем GDM
  };

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
    shell = pkgs.zsh;
    extraGroups = [ "wheel" "networkmanager" ];
    initialPassword = "1"; # Don't forget to change this password later!
  };

  # Define the state version of NixOS
  system.stateVersion = "24.05";
}
