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
      wl-clipboard
      grim
      slurp
      nautilus
      pavucontrol
      networkmanagerapplet
      fuzzel
      mako
      swaylock
      telegram-desktop
      discord
      spotify
      vlc
      mpvpaper
      loupe
      papers
      file-roller
      mangohud
      gnome-text-editor
      fragments
      xdelta
      wineWow64Packages.waylandFull
      winetricks
      distrobox
      libreoffice
      inputs.hytale-launcher.packages.${pkgs.stdenv.hostPlatform.system}.default
      vintagestory
      prismlauncher
    ];
  };
  dconf = {
    enable = true;
    settings = {
      "org/gnome/desktop/interface" = {
        color-scheme = "prefer-dark";
      };
    };
  };
  qt = {
    enable = true;
    platformTheme.name = "qtct"; # or "gnome" or "qtct"
    style = {
      name = "adwaita-dark"; # Choose "Adwaita-Dark" or "Breeze-Dark"
      package = pkgs.adwaita-qt;
    };
  };
  gtk = {
    theme = {
      name = "adw-gtk3-dark";
      package = pkgs.adw-gtk3;
    };
    # Force dark application preference in GTK3 & GTK4
    gtk3.extraConfig.gtk-application-prefer-dark-theme = 1;
    gtk4.extraConfig.gtk-application-prefer-dark-theme = 1;
    enable = true;
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
  };

  imports = [ inputs.noctalia.homeModules.default ];

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "text/html" = "firefox.desktop";
      "x-scheme-handler/http" = "firefox.desktop";
      "x-scheme-handler/https" = "firefox.desktop";
      "x-scheme-handler/about" = "firefox.desktop";
      "x-scheme-handler/unknown" = "firefox.desktop";

      "inode/directory" = "org.gnome.Nautilus.desktop";

      "image/png" = "org.gnome.Loupe.desktop";
      "image/jpeg" = "org.gnome.Loupe.desktop";
      "image/gif" = "org.gnome.Loupe.desktop";
      "image/webp" = "org.gnome.Loupe.desktop";
      "image/bmp" = "org.gnome.Loupe.desktop";
      "image/svg+xml" = "org.gnome.Loupe.desktop";

      "video/mp4" = "vlc.desktop";
      "video/x-matroska" = "vlc.desktop";
      "video/webm" = "vlc.desktop";
      "audio/mpeg" = "vlc.desktop";
      "audio/flac" = "vlc.desktop";

      "text/plain" = "org.gnome.TextEditor.desktop";

      "application/pdf" = "org.gnome.Papers.desktop";

      "application/zip" = "org.gnome.FileRoller.desktop";
      "application/x-tar" = "org.gnome.FileRoller.desktop";
      "application/x-7z-compressed" = "org.gnome.FileRoller.desktop";
      "application/vnd.rar" = "org.gnome.FileRoller.desktop";

    };
  };

  programs = {
    home-manager.enable = true;

    noctalia = {
      enable = true;
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
        command = "${pkgs.swaylock}/bin/swaylock -f";
      }
      {
        timeout = 600;
        command = "${pkgs.niri}/bin/niri msg action power-off-monitors";
      }
    ];
    events = {
      before-sleep = "${pkgs.swaylock}/bin/swaylock -f";
    };
  };
}
