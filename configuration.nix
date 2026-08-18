{ lib, pkgs, inputs, ... }:

let
  sddm-astronaut = pkgs.sddm-astronaut.override {
    embeddedTheme = "hyprland_kath";
  };
in

{
  imports = [ ./tor.nix ]
    # решает проблему курицы и яйца: при nixos-install с disko этого файла
    # физически ещё нет в репозитории на первом шаге
    ++ lib.optional (builtins.pathExists ./hardware-configuration.nix) ./hardware-configuration.nix;

  system.stateVersion = "26.05";

  nixpkgs.config.allowUnfree = true;

  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;
      connect-timeout = 5;
    };

    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 14d";
    };
  };

  boot = {
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;
    kernelParams = [ "amd_pstate=active" ];
    tmp.cleanOnBoot = true;
    extraModprobeConfig = "options thinkpad_acpi fan_control=1";
    # УБРАНО: extraModprobeConfig = "options thinkpad_acpi fan_control=1";
    # Модуль services.thinkfan сам добавляет эту опцию модпробу, когда
    # включён (nixos/modules/services/hardware/thinkfan.nix):
    #   boot.extraModprobeConfig =
    #     "options thinkpad_acpi experimental=1 fan_control=1";
    # Ручная строка здесь была не ошибкой, а чистым дублированием: тип
    # опции — lines, оба значения склеивались бы в файл modprobe.d, просто
    # без всякой пользы. Раз thinkfan включён ниже — модуль это уже делает.
  };

  networking = {
    hostName = "nixos";
    networkmanager.enable = true;
    firewall.enable = true;
    # networking.proxy.* оставлен здесь, а не перенесён в tor.nix — это
    # решение всё ещё стоит принять (см. аудит, §2.9): раз вся цепочка
    # privoxy+Tor целиком описана в tor.nix, логичнее держать проброс
    # прокси тоже там. Не трогал автоматически, чтобы не плодить лишние
    # изменения сразу в двух файлах без вашего решения.
    proxy = {
      default = "http://127.0.0.1:8118";
      noProxy = "127.0.0.1,localhost";
    };
  };

  time.timeZone = "Europe/Moscow";
  i18n.defaultLocale = "ru_RU.UTF-8";
  console.keyMap = "us";

  hardware = {
    graphics = {
      enable = true;
      enable32Bit = true; # нужно Steam / Proton для 32-битных игр
    };
    enableRedistributableFirmware = true;
    bluetooth.enable = true;
  };

  # ИСПРАВЛЕНО: services.xserver.videoDrivers = [ "amdgpu" ]; убрано.
  # Эта опция подключается только через services.xserver.enable, которого
  # нигде нет (чистый Wayland/niri, X-сервер не запускается) — без него она
  # ни на что не влияет. amdgpu и так грузится ядром/udev по PCI ID,
  # hardware.enableRedistributableFirmware уже тянет нужные прошивки.

  services.fwupd.enable = true;

  services.thinkfan = {
    enable = true;

    # Собрать thinkfan с поддержкой чтения температуры дисков через S.M.A.R.T.
    smartSupport = true;

    # Источники температуры. По умолчанию thinkfan и так использует
    # /proc/acpi/ibm/thermal — оставляем явно для читаемости и добавляем
    # k10temp (AMD) как дополнительный сенсор, если он есть в hwmon.
    sensors = [
      # Раскомментируйте и подставьте нужный путь после
      # `ls /sys/class/hwmon/*/name` -> найдите тот, что выводит "k10temp":
      {
        type = "hwmon";
        query = "/sys/class/hwmon/hwmon6/temp1_input";
      }
    ];
    fans = [
      {
        type = "tpacpi";
        query = "/proc/acpi/ibm/fan";
      }
    ];
    # Кривая скорости вентилятора: [LEVEL LOW HIGH]
    # LEVEL: 0-7 (thinkpad_acpi), "level auto", "level full-speed" или "level disengaged"
    # LOW/HIGH — температуры (°C) переключения на предыдущий/следующий уровень
    levels = [
      [ 0 0  42 ]
      [ 1 40 47 ]
      [ 3 50 57 ]
      [ 4 55 62 ]
      [ 5 60 77 ]
      [ 6 73 93 ]
      [ 7 85 32767 ]
    ];

    # Например, "-b 0" отключает bias при снижении уровня.
    extraArgs = [ "-b" "0" ];
  };

  services.fstrim.enable = true; # вместе с discard=async из disko.nix — рекомендуемая связка, не дублирование
  services.gvfs.enable = true; # нужен nautilus'у (home.nix) для корзины/MTP/сетевых шар

  services.snapper.configs.root = {
    SUBVOLUME = "/";
    ALLOW_USERS = [ "tahara" ];
    TIMELINE_CREATE = true;
    TIMELINE_CLEANUP = true;
    TIMELINE_LIMIT_HOURLY = 5;
    TIMELINE_LIMIT_DAILY = 7;
    TIMELINE_LIMIT_WEEKLY = 4;
    TIMELINE_LIMIT_MONTHLY = 3;
    TIMELINE_LIMIT_YEARLY = 0;
  };

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
    jack.enable = true;
  };

  services.power-profiles-daemon.enable = true;
  services.upower.enable = true;

  services.displayManager.sddm = {
    enable = true;
    package = pkgs.kdePackages.sddm;
    wayland.enable = true;
    extraPackages = (with pkgs; [
      kdePackages.qtmultimedia # нужен для видео-фонов/звука в теме
    ]) ++ [
      # ИСПРАВЛЕНО: раньше тема была только в environment.systemPackages.
      # По официальному примеру NixOS Wiki (SDDM Themes) пакет темы нужен
      # в обоих местах — extraPackages подключает его именно в окружение
      # самого SDDM (до входа пользователя), иначе часть темы (шрифты,
      # QML-компоненты) может не подхватываться.
      sddm-astronaut
    ];
    theme = "sddm-astronaut-theme";
  };

  environment.sessionVariables.XDG_DATA_DIRS = [
    "${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}"
    "${pkgs.gtk3}/share/gsettings-schemas/${pkgs.gtk3.name}"
  ];

  security.rtkit.enable = true;
  security.polkit.enable = true;

  programs = {
    dconf.enable = true;
    niri.enable = true;
    fish.enable = true;
    steam.enable = true;
    obs-studio.enable = true;
    gamemode.enable = true;
    wireshark.enable = true;
    # ИСПРАВЛЕНО: programs.xwayland.enable убрано. niri не пользуется этим
    # тумблером — для XWayland у него отдельный механизм, xwayland-satellite
    # (пакет ниже). Опция ставила пакет xorg.xwayland, который niri не
    # использует.
  };

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gnome pkgs.xdg-desktop-portal-gtk ];
  };

  users.users.tahara = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" "audio" "docker" "wireshark" ];
    shell = pkgs.fish;
  };

  virtualisation = {
    docker.enable = true;
    vmware.host.enable = true;
  };

  zramSwap.enable = true;

  fonts = {
    packages = with pkgs; [
      nerd-fonts.jetbrains-mono
      noto-fonts
      font-awesome
      fira-code
    ];
    fontconfig.enable = true;
  };

  environment.systemPackages = (with pkgs; [
    # Базовый набор для восстановления системы одним пользователем — держим
    # на системном уровне, чтобы был доступен даже при сломанном Home Manager.
    vim
    git
    wget
    curl
    fastfetch
    htop
    btop
    tree
    ripgrep
    fd
    ffmpeg
    lm_sensors
    jdk8

    # ПРОВЕРИТЬ: возможно, теперь ставится автоматически модулем
    # programs.niri (опция xwayland-satellite, появилась в nixpkgs вместе с
    # niri 25.08, NixOS/nixpkgs#442948, включена по умолчанию). Проверка:
    #   nix eval .#nixosConfigurations.nixos.config.programs.niri.xwayland-satellite.enable
    # Если true — эту строку можно убрать.
    xwayland-satellite

    # ПРОВЕРИТЬ: возможно, теперь ставится автоматически модулем
    # virtualisation.vmware.host (опция host.package). Проверка:
    #   nix eval .#nixosConfigurations.nixos.config.virtualisation.vmware.host.package
    # Если пакет совпадает — эту строку можно убрать.
    vmware-workstation
  ]) ++ [
    sddm-astronaut
    inputs.prismlauncher.packages.${pkgs.system}.prismlauncher # ПЕРЕНЕСЕНО из flake.nix
  ];
  # ПЕРЕНЕСЕНО в home.nix (home.packages): telegram-desktop, discord,
  # spotify, vlc, mpvpaper, eog, gedit, obsidian, fragments, xdelta, jdk21,
  # wineWow64Packages.waylandFull, winetricks, distrobox — это
  # пользовательские GUI/CLI-программы одного пользователя; их
  # установка/обновление через `home-manager switch` не требует sudo и не
  # пересобирает всю систему.
}
