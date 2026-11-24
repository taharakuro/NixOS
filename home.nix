{
  pkgs,
  lib,
  inputs,
  ...
}:

let
  # "приложение -> список MIME-типов" вместо повторения приложения в каждой строке
  mime = app: types: lib.genAttrs types (_: app);
in
{
  imports = [ inputs.noctalia.homeModules.default ];

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
      ELECTRON_OZONE_PLATFORM_HINT = "auto";
      # MOZ_ENABLE_WAYLAND убран: Firefox сам использует Wayland начиная с 121
    };

    packages = with pkgs; [
      # CLI (раньше лежали в systemPackages)
      fastfetch
      btop
      tree
      ripgrep
      fd
      ffmpeg

      # окружение рабочего стола
      wl-clipboard
      grim
      slurp
      nautilus
      pavucontrol
      networkmanagerapplet
      fuzzel
      mako

      # приложения
      telegram-desktop
      discord
      spotify
      vlc
      mpvpaper
      loupe
      papers
      file-roller
      gnome-text-editor
      fragments
      libreoffice

      # игры и Wine
      mangohud
      xdelta
      wineWow64Packages.waylandFull
      winetricks
      distrobox
      inputs.hytale-launcher.packages.${pkgs.stdenv.hostPlatform.system}.default
      vintagestory
      prismlauncher
      olympus
    ];
  };

  dconf.settings."org/gnome/desktop/interface".color-scheme = "prefer-dark";

  qt = {
    enable = true;
    platformTheme.name = "qtct";
    # package не задаём: для adwaita-dark Home Manager сам ставит и adwaita-qt (Qt5),
    # и adwaita-qt6 — с одним pkgs.adwaita-qt Qt6-приложения остаются без стиля
    style.name = "adwaita-dark";
  };

  gtk = {
    enable = true;
    theme = {
      name = "adw-gtk3-dark";
      package = pkgs.adw-gtk3;
    };
    # тёмный режим для GTK3 и GTK4 (для GTK4 — через gtk-interface-color-scheme)
    colorScheme = "dark";
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
  };

  xdg.mimeApps = {
    enable = true;
    defaultApplications =
      mime "firefox.desktop" [
        "text/html"
        "x-scheme-handler/http"
        "x-scheme-handler/https"
        "x-scheme-handler/about"
        "x-scheme-handler/unknown"
      ]
      // mime "org.gnome.Nautilus.desktop" [ "inode/directory" ]
      // mime "org.gnome.Loupe.desktop" [
        "image/png"
        "image/jpeg"
        "image/gif"
        "image/webp"
        "image/bmp"
        "image/svg+xml"
      ]
      // mime "vlc.desktop" [
        "video/mp4"
        "video/x-matroska"
        "video/webm"
        "audio/mpeg"
        "audio/flac"
      ]
      // mime "org.gnome.TextEditor.desktop" [ "text/plain" ]
      // mime "org.gnome.Papers.desktop" [ "application/pdf" ]
      // mime "org.gnome.FileRoller.desktop" [
        "application/zip"
        "application/x-tar"
        "application/x-7z-compressed"
        "application/vnd.rar"
      ];
  };

  programs = {
    # programs.home-manager.enable убран: при установке через NixOS-модуль
    # отдельная утилита home-manager не нужна, сборкой занимается nixos-rebuild.
    noctalia.enable = true;

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
}
