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
    # ОБЪЕДИНЕНО: раньше boot.extraModprobeConfig был отдельной строкой в
    # другом месте файла — здесь он логичнее, среди остального boot.*
    extraModprobeConfig = "options thinkpad_acpi fan_control=1";
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
  i18n.defaultLocale = "en_US.UTF-8";
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

  services = {
    thinkfan = {
      enable = true;
      sensors = [
        { type = "hwmon"; query = "/sys/devices/platform/thinkpad_hwmon/hwmon/hwmon*/temp*_input"; }
        { type = "hwmon"; query = "/sys/devices/pci0000:00/0000:00:18.3/hwmon/hwmon*/temp1_input"; }
      ];
      levels = [
        [0 0 52]
        [1 48 60]
        [2 55 65]
        [3 60 72]
        [5 67 80]
        [7 75 32767]
      ];
    };

    fstrim.enable = true; # вместе с discard=async из disko.nix — рекомендуемая связка, не дублирование
    gvfs.enable = true; # нужен nautilus'у (home.nix) для корзины/MTP/сетевых шар

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

    power-profiles-daemon.enable = true;
    upower.enable = true;

    displayManager.sddm = {
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
  };

  security.rtkit.enable = true;
  security.polkit.enable = true;

  programs = {
    dconf.enable = true;
    niri.enable = true;
    fish.enable = true;
    steam.enable = true;
    obs-studio.enable = true;
    gamemode.enable = true;
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
    extraGroups = [ "wheel" "networkmanager" "video" "audio" "docker" ];
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
