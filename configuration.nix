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
    kernelPackages = pkgs.linuxPackages_latest;

    kernelParams = [
      # активный EPP-драйвер SMU для Ryzen 6xxx "Rembrandt" (нужно ядро >=6.3, у нас
      # linuxPackages_latest — ок). https://docs.kernel.org/admin-guide/pm/amd-pstate.html
      "amd_pstate=guided"
      # На этом поколении AMD-платформ рабочего S3 нет (EC/прошивка его не тянут).
      # ArchWiki (Lenovo ThinkPad T14 (AMD) Gen 3#Firmware) прямо предупреждает не
      # переключать suspend mode в UEFI на "Linux (S3)" — машина зависает при
      # уходе в сон. s2idle (он же modern standby/S0i3) — единственный рабочий режим.
      "mem_sleep_default=s2idle"
    ];

    # k10temp — hwmon-датчик температуры ядра Ryzen. По PCI ID обычно подгружается
    # сам, но явная загрузка нужна, чтобы thinkfan ниже гарантированно видел
    # /sys/class/hwmon/*/name == "k10temp" уже на момент своего старта.
    kernelModules = [ "k10temp" ];

    tmp.cleanOnBoot = true;
  };

  networking = {
    hostName = "nixos";
    networkmanager.enable = true;
    firewall.enable = true;
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

  services.fwupd.enable = true;
  # Работает, только если в BIOS включено "Enable Windows Update UEFI Update"
  # (Security -> ...). Также известна проблема: прошивка версии 0.1.40 у T14s Gen 3
  # (AMD) вызывает сбои — если ловите странности после обновления BIOS, ArchWiki
  # (Lenovo ThinkPad T14s (AMD) Gen 3) прямо предупреждает про эту версию.

  # === Fan control (thinkfan) ===================================================
  # У T14/T14s Gen 3 (AMD) штатная EC-кривая вентилятора ведёт себя "истерично" —
  # обороты дёргаются вверх-вниз без видимой связи с нагрузкой (тема на форуме
  # Lenovo: "T14 Gen 3 AMD chaotic/erratic fan control"). ArchWiki по T14s (AMD)
  # Gen 6 прямо подтверждает, что эти устройства поддерживаются thinkfan и это
  # штатное решение проблемы. Опрашиваем сразу два источника температуры —
  # tpacpi (данные EC, те же, что видит прошивка) и k10temp (реальный Tctl ядра из
  # hwmon) — thinkfan берёт максимум по всем сенсорам, так надёжнее, чем полагаться
  # только на EC. Модуль NixOS сам добавляет
  # `options thinkpad_acpi experimental=1 fan_control=1` в modprobe.d — руками
  # прописывать не нужно.
  services.thinkfan = {
    enable = true;
    sensors = [
      { type = "tpacpi"; query = "/proc/acpi/ibm/thermal"; }
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
      [ 0 0  50 ]
      [ 1 45 58 ]
      [ 2 53 62 ]
      [ 3 58 66 ]
      [ 4 62 70 ]
      [ 5 66 75 ]
      [ 6 71 80 ]
      [ 7 77 32767 ]
    ];
  };

  services.dnsmasq = {
    enable = true;
    settings = {
      enable-tftp = true;
      tftp-root = "/srv/tftp";
      dhcp-range = "192.168.0.1,192.168.0.66";
    };
  };

  networking.firewall.allowedUDPPorts = [ 69 67 ];


  # Пороги заряда батареи через нативный интерфейс thinkpad_acpi (ядро >=5.17,
  # /sys/class/power_supply/BAT0/charge_control_{start,end}_threshold) — без
  # tp_smapi/acpi_call, которые для этой модели не нужны и местами не работают.
  # 75/80 — консервативный ориентир для продления жизни батареи, если ноутбук
  # часто работает от сети; подправьте под свой сценарий использования.
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="power_supply", KERNEL=="BAT0", ATTR{charge_control_start_threshold}="75", ATTR{charge_control_end_threshold}="80"
  '';
  # ================================================================================

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

  services.power-profiles-daemon.enable = true; # для AMD ноутбуков лучше держать батарею, чем tlp — не включайте оба сразу
  services.upower.enable = true;

  services.displayManager.sddm = {
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
    xwayland-satellite

  ]) ++ [
    sddm-astronaut
    inputs.prismlauncher.packages.${pkgs.system}.prismlauncher
  ];
}
