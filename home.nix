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
    };
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

  dconf = {
    enable = true;
    settings = {
      "org/gnome/desktop/interface" = {
        color-scheme = "prefer-dark";
        # Без этого ключа xdg-desktop-portal-gnome (Settings-портал, которым
        # пользуется Firefox под Wayland) сообщает приложениям пару
        # "тёмный режим включён" + "тема — дефолтная светлая Adwaita" (её
        # тут нет — реальная тема ставится ниже через gtk.theme.name, а
        # это пишет только settings.ini, до dconf/портала не долетает).
        # Firefox в этом рассинхроне красит текст меню тем же цветом, что
        # и фон — снаружи выглядит как "пропали буквы". Дублируем то же
        # имя темы сюда, чтобы портал отдавал согласованную пару.
        gtk-theme = "adw-gtk3-dark";
      };
    };
  };
  qt = {
    enable = true;
    platformTheme.name = "qtct"; # or "gnome" or "qtct"
    style = {
      name = "adwaita-dark";   # Choose "Adwaita-Dark" or "Breeze-Dark"
      package = pkgs.adwaita-qt;
    };
  };
  gtk = {
    # Example: Adwaita-dark, or replace with pkgs.orchis-theme, pkgs.catppuccin-gtk, etc.
    theme = {
      name = "Adwaita-dark";
      package = pkgs.gnome.gnome-themes-extra;
    };
    font = {
      name = "DejaVu Sans 11";
      package = pkgs.dejavu_fonts;
    };
    enable = true;
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
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
