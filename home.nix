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
      # swaylock — не основной лок-скрин (тот встроен в noctalia, см.
      # keybinds.kdl и services.swayidle ниже), а аварийный, на случай
      # если сам noctalia упадёт или ещё не успел запуститься. PAM для
      # него настроен в desktop.nix (security.pam.services.swaylock).
      swaylock
      nautilus
      pavucontrol
      networkmanagerapplet
      # mako и fuzzel убраны: у noctalia есть собственные уведомления и
      # лаунчер (Mod+D уже вызывает "noctalia msg panel-toggle launcher"
      # в keybinds.kdl, а не fuzzel). mako — отдельный демон
      # уведомлений, конкурирующий с noctalia за один и тот же
      # D-Bus-интерфейс org.freedesktop.Notifications: держать оба сразу
      # значит гадать, какой из них ответит на конкретное уведомление.
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
        gtk-theme = "Adwaita-dark";
      };
    };
  };
  qt = {
    enable = true;
    platformTheme.name = "qtct";
    style = {
      name = "adwaita-dark";
      package = pkgs.adwaita-qt;
    };
  };
  gtk = {
    theme = {
      name = "Adwaita-dark";
      package = pkgs.gnome-themes-extra;
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
      # Схема Noctalia активно меняется (v5 сейчас в бете: TOML вместо
      # JSON, у части виджетов сменился формат ключей — например, часы
      # там задаются как отдельный виджет со своим settings.format, а не
      # плоским clock.format). Неизвестные ключи Noctalia не роняет
      # сборку — молча игнорирует с предупреждением в логе, так что
      # "собралось" не значит "применилось". Если формат часов или
      # положение бара после rebuild выглядят не так, как ниже, сверьтесь
      # с актуальной схемой на https://docs.noctalia.dev/ для вашей
      # версии (v4 Quickshell/JSON или v5 TOML).
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

  # Агент авторизации polkit: niri, в отличие от полноценного DE, сам
  # его не поднимает, а без агента приложения, которым нужны root-права
  # через polkit (точки монтирования в Nautilus, часть действий
  # NetworkManager и т.д.), просто не покажут диалог с паролем.
  # security.polkit.enable в desktop.nix включает только сам демон, а
  # не GUI-агента — это разные вещи.
  # См. https://wiki.nixos.org/wiki/Niri (раздел "Example systemd Setup")
  services.polkit-gnome.enable = true;

  services.swayidle = {
    enable = true;
    timeouts = [
      {
        timeout = 300;
        # Тот же вызов, что и в Mod+Alt+L из keybinds.kdl — родной
        # лок-скрин noctalia, а не отдельный swaylock. Раньше здесь стоял
        # голый "swaylock -f", хотя ручной хоткей блокирует экран через
        # noctalia — на практике это два разных клиента одного и того же
        # протокола ext-session-lock-v1, и выглядели они по-разному в
        # зависимости от того, сработал таймаут или хоткей.
        command = "qs -c noctalia-shell ipc call lockScreen lock";
      }
      {
        timeout = 600;
        command = "niri msg action power-off-monitors";
      }
    ];
    events = [
      {
        event = "before-sleep";
        command = "qs -c noctalia-shell ipc call lockScreen lock";
      }
    ];
  };
}
