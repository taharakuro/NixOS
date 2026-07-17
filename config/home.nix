{ pkgs, inputs, ... }:

{
  home = {
    username = "tahara";
    homeDirectory = "/home/tahara";
    stateVersion = "26.05";
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
      fastfetch
    ];
  };

  imports = [ inputs.noctalia.homeModules.default ];

  programs = {
    home-manager.enable = true;
    noctalia-shell = {
      enable = true;
      settings = {
        bar.position = "top";
        clock.format = "HH:mm";
      };
    };
    niri.settings = {
      spawn-at-startup = [ { command = [ "noctalia-shell" ]; } ];
      binds = {
        "Mod+Return".action.spawn = [ "kitty" ];
        "Mod+D".action.spawn = [ "noctalia-shell" "ipc" "call" "launcher" "toggle" ];
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
