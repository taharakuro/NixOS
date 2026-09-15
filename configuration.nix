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

  # ВРЕМЕННЫЙ откат linux-firmware: сборка 20260910 содержит регресс в
  # прошивке DMCUB (Rembrandt/Phoenix iGPU), из-за которого dmesg заливает
  # бесконечными "*ERROR* dc_dmub_srv_log_diagnostic_data: DMCUB error -
  # collecting diagnostic data" (см. gitlab.freedesktop.org/drm/amd/-/issues/3913
  # и аналогичный репорт на форуме Arch про 20260910-1 на Radeon 680M).
  # Откатываемся на 20260810 — последнюю известную рабочую сборку.
  # TODO: убрать этот overlay, когда апстрим выкатит фикс в свежей linux-firmware
  # (проверять: nix path-info -r /run/current-system | grep -i linux-firmware).
  nixpkgs.overlays = [
    (final: prev: {
      linux-firmware = prev.linux-firmware.overrideAttrs (old: rec {
        src = prev.fetchzip {
          url = "https://mirrors.edge.kernel.org/pub/linux/kernel/firmware/linux-firmware-20260810.tar.gz";
        };
      });
    })
  ];

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
    kernelPackages = pkgs.linuxPackages_zen;
    kernelModules = [ "k10temp" ];
    tmp.cleanOnBoot = true;
    kernel.sysctl = {
      "net.ipv4.tcp_timestamps" = 1;
    };
  };

  # zram как быстрый первый уровень подкачки; 12G-раздел в disko.nix остаётся
  # вторым уровнем и нужен в первую очередь для гибернации (resumeDevice).
  # priority выше, чем у дискового swap (по умолчанию у него -2 в fstab),
  # поэтому ядро всегда выбирает zram первым и уходит на диск, только когда
  # сжатого RAM-свопа не хватает.
  # memoryPercent = 100% от 14G ОЗУ — не значит "займёт всю память": в zram
  # реально расходуется место только под уже сжатые страницы (обычно ~2-3x
  # сжатие на zstd), а при 14G и одновременных Docker/VMware/играх свободный
  # запас на случай пиков важнее, чем экономия этих процентов.
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 100;
    priority = 100;
  };

  networking = {
    hostName = "nixos";
    networkmanager.enable = true;
    firewall.enable = true;
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
    fwupd.enable = true;
    # Работает, только если в BIOS включено "Enable Windows Update UEFI Update"
    # (Security -> ...). Также известна проблема: прошивка версии 0.1.40 у T14s Gen 3
    # (AMD) вызывает сбои — если ловите странности после обновления BIOS, ArchWiki
    # (Lenovo ThinkPad T14s (AMD) Gen 3) прямо предупреждает про эту версию.

    # Пороги заряда батареи через нативный интерфейс thinkpad_acpi (ядро >=5.17,
    # /sys/class/power_supply/BAT0/charge_control_{start,end}_threshold) — без
    # tp_smapi/acpi_call, которые для этой модели не нужны и местами не работают.
    # 75/80 — консервативный ориентир для продления жизни батареи, если ноутбук
    # часто работает от сети; подправьте под свой сценарий использования.
    udev.extraRules = ''
      ACTION=="add", SUBSYSTEM=="power_supply", KERNEL=="BAT0", ATTR{charge_control_start_threshold}="75", ATTR{charge_control_end_threshold}="80"
    '';

    fstrim.enable = true; # вместе с discard=async из disko.nix — рекомендуемая связка, не дублирование
    gvfs.enable = true; # нужен nautilus'у (home.nix) для корзины/MTP/сетевых шар

    thinkfan = {
      enable = true;
      sensors = [
        { type = "hwmon"; query = "/sys/class/hwmon"; name = "k10temp"; indices = [ 1 ]; } # Tctl
      ];
      fans = [
        { type = "tpacpi"; query = "/proc/acpi/ibm/fan"; }
      ];
      # [уровень, LOW, HIGH]: LOW — температура сброса на уровень ниже, HIGH — подъёма
      # на уровень выше. Достаточный зазор LOW/HIGH внутри уровня и так между
      # соседними уровнями — то, чего не хватает штатной прошивке (отсюда и дёрганья).
      # Подстройте под себя после недели наблюдений (watch -n1 sensors).
      levels = [
        [ 0 0 45 ]
        [ "level auto" 45 80 ]
        [ "level disengaged" 80 255 ]
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

    power-profiles-daemon.enable = true; # для AMD ноутбуков лучше держать батарею, чем tlp — не включайте оба сразу
    upower.enable = true;

    displayManager.sddm = {
      enable = true;
      package = pkgs.kdePackages.sddm;
      wayland.enable = true;
      extraPackages = (with pkgs; [
        kdePackages.qtmultimedia # нужен для видео-фонов/звука в теме
      ]) ++ [
        sddm-astronaut
      ];
      theme = "sddm-astronaut-theme";
    };
  };

  environment.sessionVariables.XDG_DATA_DIRS = [
    "${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}"
    "${pkgs.gtk3}/share/gsettings-schemas/${pkgs.gtk3.name}"
  ];

  security = {
    rtkit.enable = true;
    polkit.enable = true;
  };

  programs = {
    dconf.enable = true;
    niri.enable = true;
    fish.enable = true;
    steam.enable = true;
    obs-studio.enable = true;
    gamemode.enable = true;
    wireshark.enable = true;
    amnezia-vpn.enable = true;
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
    vim
    udisks
    gnome-disk-utility
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
    xwayland-satellite
  ]) ++ [
    sddm-astronaut
  ];
}
