{ pkgs, ... }:

{
  # hardware-configuration.nix подключается безусловно: если файл потерялся
  # или не добавлен в git, сборка упадёт сразу и явно. Раньше pathExists
  # молча пропускал его, и система собиралась без nvme/kvm-amd в initrd.
  imports = [
    ./hardware-configuration.nix
    ./tor.nix
  ];

  system.stateVersion = "26.05";

  nixpkgs.config.allowUnfree = true;

  nix = {
    settings = {
      trusted-users = [
        "root"
        "tahara"
      ];
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      connect-timeout = 5;
      warn-dirty = false;

      # то же, что nixConfig во flake.nix, но постоянно и без вопросов при сборке
      extra-substituters = [ "https://noctalia.cachix.org" ];
      extra-trusted-public-keys = [
        "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
      ];
    };

    # отдельный таймер вместо auto-optimise-store: дедупликация не тормозит сборки
    optimise.automatic = true;

    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 14d";
    };
  };

  boot = {
    loader.systemd-boot = {
      enable = true;
      # ESP всего 512M, а каждое поколение с zen-ядром кладёт туда ядро + initrd
      configurationLimit = 10;
      # без LUKS правка cmdline в меню загрузки (init=/bin/sh) даёт root за секунды
      editor = false;
    };
    loader.efi.canTouchEfiVariables = true;
    kernelPackages = pkgs.linuxPackages_zen;
    extraModprobeConfig = "options thinkpad_acpi fan_control=1"; # нужно для thinkfan
    tmp.cleanOnBoot = true;
  };

  # zram — быстрый первый уровень подкачки. 14G-раздел из disko.nix остаётся
  # вторым уровнем и нужен прежде всего для гибернации (resumeDevice).
  # priority = 100 выше, чем у дискового swap, поэтому ядро сначала заполняет
  # zram. 100% ОЗУ — это лишь лимит: реально занимается только сжатый объём.
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 100;
    priority = 100;
  };

  networking = {
    hostName = "nixos";
    networkmanager.enable = true;
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

  services = {
    # Обновления прошивок работают, только если в BIOS включено
    # "Enable Windows Update UEFI Update" (раздел Security). Известная проблема:
    # прошивка 0.1.40 у T14s Gen 3 (AMD) вызывает сбои — ArchWiki предупреждает
    # об этом прямо; если после обновления BIOS пошли странности, смотрите туда.
    fwupd.enable = true;

    # Пороги заряда батареи через нативный интерфейс thinkpad_acpi (ядро >= 5.17,
    # /sys/class/power_supply/BAT0/charge_control_{start,end}_threshold) — без
    # tp_smapi/acpi_call. 75/80 — консервативный ориентир, если ноутбук часто
    # работает от сети; подправьте под свой сценарий.
    udev.extraRules = ''
      ACTION=="add", SUBSYSTEM=="power_supply", KERNEL=="BAT0", ATTR{charge_control_start_threshold}="75", ATTR{charge_control_end_threshold}="80"
    '';

    btrfs.autoScrub = {
      enable = true;
      # без этого скрабится каждая точка монтирования отдельно: /, /home, /nix
      # и /.snapshots — это одна и та же ФС, т.е. четыре скраба подряд
      fileSystems = [ "/" ];
    };
    fstrim.enable = true; # заодно чистит vfat-ESP, до которой discard=async не дотягивается
    udisks2.enable = true; # монтирование дисков из nautilus/gnome-disks
    gvfs.enable = true; # нужен nautilus'у (home.nix) для корзины/MTP/сетевых шар

    thinkfan = {
      enable = true;
      sensors = [
        {
          type = "hwmon";
          query = "/sys/class/hwmon";
          name = "k10temp";
          indices = [ 1 ]; # Tctl
        }
      ];
      fans = [
        {
          type = "tpacpi";
          query = "/proc/acpi/ibm/fan";
        }
      ];
      levels = [
        # [уровень LOW HIGH]: вниз при T < LOW, вверх при T > HIGH.
        # LOW каждого уровня меньше HIGH предыдущего → зазор 5 °C, дёрганий нет.
        # Минимальный уровень 1: вентилятор не останавливается совсем.
        [ 1 0 50 ]
        [ 2 45 55 ]
        [ 3 50 60 ]
        [ 4 55 65 ]
        [ 5 60 70 ]
        [ 6 65 75 ]
        [ 7 70 82 ]
        [ "level disengaged" 78 255 ]
      ];
    };

    snapper.configs.root = {
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

    pipewire = {
      enable = true;
      alsa.enable = true;
      pulse.enable = true;
      jack.enable = true;
    };

    power-profiles-daemon.enable = true; # для AMD-ноутбуков лучше tlp; не включайте оба сразу
    upower.enable = true;

    displayManager.noctalia-greeter = {
      enable = true;
      settings.cursor = {
        theme = "Bibata-Modern-Ice";
        size = 12;
        path = pkgs.bibata-cursors;
      };
    };
  };

  # TODO: проверить, нужен ли ещё этот костыль — убрать, пересобрать и посмотреть,
  # не пропали ли настройки GTK/dconf в приложениях без обёртки.
  environment.sessionVariables.XDG_DATA_DIRS = [
    "${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}"
    "${pkgs.gtk3}/share/gsettings-schemas/${pkgs.gtk3.name}"
  ];

  security = {
    rtkit.enable = true;
    polkit.enable = true;
    pam.services = {
      # swaylock ставится из home.nix, а PAM-сервис для него нужен на уровне
      # системы — иначе пароль не примется и экран не разблокируется.
      swaylock = { };
      # разблокировка gnome-keyring (его включает programs.niri) при входе через SDDM
      sddm.enableGnomeKeyring = true;
    };
  };

  programs = {
    dconf.enable = true;
    niri.enable = true;
    fish.enable = true;
    steam = {
      enable = true;
      extraCompatPackages = [ pkgs.proton-ge-bin ];
    };
    gamescope.enable = true;
    obs-studio.enable = true;
    gamemode.enable = true;
    wireshark = {
      enable = true;
      # по умолчанию wireshark-cli; нужен полный пакет с GUI
      package = pkgs.wireshark;
    };
    amnezia-vpn.enable = true;
    nix-ld.enable = true; # запуск сторонних (не-Nix) бинарников
    gnome-disks.enable = true; # gnome-disk-utility
  };

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ]; # portal-gnome уже добавляет programs.niri
  };

  users.users.tahara = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
      "video"
      "audio"
      "docker" # = root без пароля; см. rootless docker как более безопасную альтернативу
      "wireshark"
    ];
    shell = pkgs.fish;
  };

  virtualisation = {
    docker = {
      enable = true;
      autoPrune = {
        enable = true;
        dates = "weekly";
      };
    };
    vmware.host.enable = true;
  };

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
    font-awesome
    fira-code
  ];

  # Только то, что нужно системе и root. Пользовательские утилиты — в home.nix.
  environment.systemPackages = with pkgs; [
    vim
    git
    wget
    curl
    lm_sensors
    xdg-user-dirs
    xdg-user-dirs-gtk
    xwayland-satellite
  ];
}
