{ lib, pkgs, ... }:

{
  # hardware-configuration.nix появляется только после установки на
  # конкретное железо (nixos-generate-config на целевой машине). Условный
  # импорт нужен, чтобы disko мог вычислить disko.devices из этого же
  # флейка ещё ДО того, как этот файл закоммичен в репозиторий — иначе
  # вычисление всей конфигурации падает с "file not found" на самом первом
  # шаге (партиционировании), когда файла ещё физически не существует.
  imports = [ ./tor.nix ]
    ++ lib.optional (builtins.pathExists ./hardware-configuration.nix) ./hardware-configuration.nix;

  system.stateVersion = "26.05";

  nixpkgs.config.allowUnfree = true;

  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;
    };

    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 14d";
    };
  };

  networking = {
    hostName = "nixos";
    networkmanager.enable = true;
    firewall.enable = true;
  };

  time.timeZone = "Europe/Moscow";
  i18n.defaultLocale = "ru_RU.UTF-8";
  console.keyMap = "us";

  boot = {
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;
    kernelParams = [ "amd_pstate=active" ];
    tmp.cleanOnBoot = true;
  };

  hardware = {
    graphics = {
      enable = true;
      enable32Bit = true; # нужно Steam / Proton для 32-битных игр
    };
    enableRedistributableFirmware = true;
    bluetooth.enable = true;
  };
  services.xserver.videoDrivers = [ "amdgpu" ];
  services.fstrim.enable = true;

  zramSwap.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
    jack.enable = true;
  };
  security.rtkit.enable = true;

  services = {
    power-profiles-daemon.enable = true;
    upower.enable = true;
    greetd = {
      enable = true;
      settings.default_session = {
        command = "${lib.getExe pkgs.tuigreet} --cmd niri-session";
        user = "greeter";
      };
    };
  };

  security.polkit.enable = true;
  programs = {
    dconf.enable = true;
    niri.enable = true;
    fish.enable = true;
    steam.enable = true;
    xwayland.enable = true;
  };

  # niri по умолчанию (через свой niri-portals.conf) шлёт запросы
  # Screenshot/ScreenCast в xdg-desktop-portal-gnome, а не в -wlr — так что
  # именно gnome-портал и нужно ставить, чтобы шаринг экрана/скриншоты
  # реально работали. -gtk оставляем для FileChooser и обычных GTK-приложений.
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gnome pkgs.xdg-desktop-portal-gtk ];
  };

  users.users.tahara = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" "audio" "docker" ];
    shell = pkgs.fish;
  };

  virtualisation.docker.enable = true;

  fonts = {
    packages = with pkgs; [
      nerd-fonts.jetbrains-mono
      noto-fonts
      font-awesome
    ];
    fontconfig.enable = true;
  };

  environment.systemPackages = with pkgs; [
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
    telegram-desktop
    xwayland-satellite
  ];
}
