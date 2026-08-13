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

      # ПРОВЕРИТЬ: Noctalia сама позиционируется как all-in-one шелл со
      # своими встроенными уведомлениями, лончером и экраном блокировки.
      # fuzzel/mako/swaylock ниже могут их дублировать (в частности, у
      # mako и встроенных уведомлений Noctalia может быть конфликт за
      # DBus-имя org.freedesktop.Notifications — выигрывает тот, кто
      # запустился первым). Ничего не убрано — решите сами:
      #   а) довериться панелям Noctalia → удалить fuzzel/mako/swaylock
      #      и в services.swayidle ниже заменить `swaylock -f` на IPC-
      #      команду Noctalia (см. "IPC Command Reference" в её доках);
      #   б) оставить как есть → тогда стоит явно отключить
      #      соответствующие панели/сервисы у Noctalia, если такая
      #      возможность у неё предусмотрена, чтобы не было двух
      #      процессов, отвечающих за одно и то же.
      fuzzel
      mako
      swaylock

      # ПЕРЕНЕСЕНО из configuration.nix (environment.systemPackages):
      # пользовательские GUI/CLI-программы одного пользователя. Через
      # `home-manager switch` их установка/обновление не требует sudo и
      # не пересобирает всю систему (в отличие от nixos-rebuild switch).
      telegram-desktop
      discord
      spotify
      vlc
      mpvpaper
      eog
      gedit
      obsidian
      fragments
      xdelta
      jdk21
      wineWow64Packages.waylandFull
      winetricks
      distrobox
      blockbench
      wireshark
      inkscape
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

    # ИСПРАВЛЕНО (нужна ваша сверка): noctalia.url в flake.nix закреплён на
    # ветке `cachix` репозитория noctalia-dev/noctalia — это Noctalia v5
    # (сейчас в статусе beta, нативный шелл без Quickshell). У v5 другая
    # схема настроек: панель — именованная таблица `bar.<имя>` (шаблон,
    # клонируется на каждый монитор), а часы — не отдельная плоская секция
    # `clock`, а виджет внутри списка widgets.left/center/right. Старая
    # схема (bar.position / clock.format, как было раньше) сборку не
    # ломает, но и не факт что реально применяется — Noctalia молча
    # игнорирует неизвестные ключи с warning в своём логе, а не с ошибкой
    # nixos-rebuild.
    #
    # Ниже — реконструкция под актуальную схему (верхняя панель, часы
    # HH:mm), сохраняющая исходный смысл настройки. Точные имена виджетов и
    # их settings.* стоит свериться с вашей версией пакета:
    # docs.noctalia.dev/v5/bar/ (или после первого запуска через GUI-
    # настройки Noctalia посмотреть получившийся ~/.config/noctalia/settings.toml
    # и перенести нужное обратно в Nix).
    noctalia = {
      enable = true;
      settings = {
        bar."default" = {
          position = "top";
          widgets.left = [
            { type = "Clock"; settings.format = "HH:mm"; }
          ];
        };
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
