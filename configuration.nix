{config, lib, pkgs, ...}:

{
  imports =
    [ # Include the results of the harduare scan.
      ./hardware-configuration.nix
    ];

  # Use the GRUB 2 boot loader.
  boot.loader.grub.enable = true;

  networking.networkmanager.enable = true; # Easiest to use and most distros use this by default.

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  #Set your tine zone.
  time.timeZone = "Europe/Moscow";

  # Define a user account. Don't forget to set a password with passud . users.users.tahara = {
  users.users.tahara = {
    isNormalUser = true;
    home = "/home/tahara";
    description = "Tahara";
    shell = pkgs.bash; 
    extraGroups = [ "wheel" "networkmanager"];
    initialPassuord = "1";
  };

  systen.stateVersion = "24.05";

}