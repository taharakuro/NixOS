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

  # Приложения по умолчанию (пишется в ~/.config/mimeapps.list).
  # xdg-desktop-portal (Screenshot/OpenURI и т.п. из configuration.nix)
  # и GTK/Qt-приложения читают именно этот файл, а не что-то отдельное
  # под niri. Список desktop-id можно свериться командой:
  #   ls /run/current-system/sw/share/applications/ ~/.nix-profile/share/applications/
  # После `home-manager switch` проверить: xdg-mime query default text/html
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      # Браузер — firefox из programs.firefox.enable ниже
      "text/html" = "firefox.desktop";
      "x-scheme-handler/http" = "firefox.desktop";
      "x-scheme-handler/https" = "firefox.desktop";
      "x-scheme-handler/about" = "firefox.desktop";
      "x-scheme-handler/unknown" = "firefox.desktop";

      # Файловый менеджер — nautilus из home.packages выше
      "inode/directory" = "org.gnome.Nautilus.desktop";

      # Просмотр изображений — eog из configuration.nix
      "image/png" = "org.gnome.eog.desktop";
      "image/jpeg" = "org.gnome.eog.desktop";
      "image/gif" = "org.gnome.eog.desktop";
      "image/webp" = "org.gnome.eog.desktop";
      "image/bmp" = "org.gnome.eog.desktop";
      "image/svg+xml" = "org.gnome.eog.desktop";

      # Видео/аудио — vlc из configuration.nix
      "video/mp4" = "vlc.desktop";
      "video/x-matroska" = "vlc.desktop";
      "video/webm" = "vlc.desktop";
      "audio/mpeg" = "vlc.desktop";
      "audio/flac" = "vlc.desktop";

      # Текстовые файлы — gedit из configuration.nix
      "text/plain" = "org.gnome.gedit.desktop";

      # PDF — если добавите просмотрщик PDF, впишите его .desktop сюда;
      # сейчас в пакетах PDF-вьювера нет, поэтому не заполняю.
    };
  };

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
