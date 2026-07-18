{ pkgs, inputs, ... }:

{
  home = {
    username = "tahara";
    homeDirectory = "/home/tahara";
    stateVersion = "26.05";
    pointerCursor = {
      gtk.enable = true;
      x11.enable = true;
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Ice";
      size = 24;
    sessionVariables = {
      NIXOS_OZONE_WL = "1";
      MOZ_ENABLE_WAYLAND = "1";
      ELECTRON_OZONE_PLATFORM_HINT = "auto";
    };
    packages = with pkgs; [
      fuzzel
      wl-clipboard
      grim
      slurp
      swaylock
      mako
      nautilus
      pavucontrol
      networkmanagerapplet
    ];
  };

  imports = [ inputs.noctalia.homeModules.default ];

  programs = {
    home-manager.enable = true;
    noctalia = {
      enable = true;
      settings = {
        bar.position = "top";
        clock.format = "HH:mm";
      };
    };
    kitty = {
      enable = true;
      settings = {
        font_family = "JetBrainsMono Nerd Font";
        font_size = 12;
      };
    };
    fish.enable = true;
    firefox.enable = true;
    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };
  };

  services.swayidle = {
    enable = true;
    timeouts = [
      {
        timeout = 300;
        command = "swaylock -f";
      }
      {
        timeout = 600;
        command = "niri msg action power-off-monitors";
      }
    ];
    events = [
      {
        event = "before-sleep";
        command = "swaylock -f";
      }
    ];
  };
}
