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
    extraModprobeConfig = '' options thinkpad_acpi fan_control=1 '';
    tmp.cleanOnBoot = true;
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

  services = {
    thinkfan = {
      extraArgs = [ "-s" "5" ];
      enable = true;
      smartSupport = false;
      sensors = [

        # ИСПРАВЛЕНО (было потеряно): EC-термозоны через thinkpad_acpi —
        # это дефолт самого модуля services.thinkfan в nixpkgs
        # (nixos/modules/services/hardware/thinkfan.nix), а не что-то
        # добавленное вручную. В прошлой правке этот сенсор был полностью
        # вытеснен единственным k10temp ниже — thinkfan видел только
        # температуру CPU-пакета и переставал реагировать на прогрев в
        # остальных зонах EC (в т.ч. ту, которую сама прошивка использует
        # для родной логики вентилятора). indices не указаны намеренно —
        # берутся все доступные зоны, как в дефолте модуля; старый баг
        # ядра, путавший служебный EC-регистр (ID блока питания) с
        # температурой сенсора #11, пофикшен апстримом ("thinkpad_acpi:
        # Correct thermal sensor allocation") и давно есть в стабильных
        # ветках, так что для 26.05 не актуален.
        { type = "tpacpi"; query = "/proc/acpi/ibm/thermal"; }

        # CPU (Tctl) через k10temp — точнее и быстрее реагирует, чем
        # опрашиваемые через EC зоны выше.
        # ИСПРАВЛЕНО: комментарий здесь раньше называл этот сенсор
        # "встроенным Radeon (amdgpu, edge-температура)" — это ошибка.
        # k10temp физически читает только температуру CPU-пакета (Tctl),
        # к GPU он не имеет отношения ни на одном Ryzen. На Ryzen 7 PRO
        # 6850U (Rembrandt, T14s Gen3 AMD) этот hwmon отдаёт единственный
        # сенсор — Tctl как temp1_input, так что indices = [1] сам по
        # себе был верным, ошибался только комментарий.
        { type = "hwmon"; query = "/sys/class/hwmon"; name = "k10temp"; indices = [ 1 ]; }

        # ДОБАВЛЕНО: собственно встроенный Radeon 680M — то, что
        # предыдущая версия комментария выше ошибочно приписывала
        # k10temp. На APU это отдельный hwmon с именем "amdgpu"
        # (edge-температура, temp1_input). Без этого сенсора thinkfan
        # вообще не видел нагрузку GPU — важно под Proton/Steam (см.
        # programs.steam в этом файле), где нагрузка часто GPU-bound, а
        # CPU-пакет при этом греется слабо.
        { type = "hwmon"; query = "/sys/class/hwmon"; name = "amdgpu"; indices = [ 1 ]; }

        # ДОБАВЛЕНО: NVMe (единственный диск, см. disko.nix) —
        # compress=zstd:3 + snapper (см. services.snapper ниже) дают
        # заметную фоновую нагрузку на запись, накопитель может
        # прогреться быстрее, чем это отследят зоны EC/CPU/GPU выше.
        # optional = true: composite-сенсор есть почти всегда, но имя
        # hwmon-каталога и число temp*_input отличаются между прошивками
        # NVMe — если после первого запуска thinkfan ругается на этот
        # сенсор, проверьте `cat /sys/class/hwmon/hwmon*/name` и
        # поправьте indices, не убирая optional.
        { type = "hwmon"; query = "/sys/class/hwmon"; name = "nvme"; indices = [ 1 ]; optional = true; }

      ];
      fans = [
        { type = "tpacpi"; query = "/proc/acpi/ibm/fan"; }
      ];
      levels = [
        [0 0  40]
        [1 30 48]   # было 35/45 — мало для скачков возле 45-46°
        [2 38 55]
        [3 48 60]
        [4 53 65]
        [5 58 70]
        [6 63 75]
        [7 68 80]
        ["level disengaged" 75 32767]
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
