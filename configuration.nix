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

    # Свежее ядро важно именно для T14s Gen3 AMD (Rembrandt/Ryzen 6000 PRO,
    # RDNA2 iGPU, Wi-Fi Qualcomm QCNFA765 через ath11k, звук через AMD ACP)
    # — вся эта связка активно донастраивалась в апстриме уже после релиза
    # железа, и часть фиксов (в т.ч. resume-баги ath11k, PSR-баги amdgpu)
    # попадала только в свежие ядра, которых нет в стабильной ветке
    # nixpkgs 26.05. ИСПРАВЛЕНО: раньше здесь была ошибочно указана
    # Wi-Fi-карта MediaTek MT7921 и кодек cs35l41 — см. подробную
    # ArchWiki-справку про Wi-Fi ниже в hardware.*.
    kernelPackages = pkgs.linuxPackages_latest;

    kernelParams = [
      "amd_pstate=active"
      # ThinkPad'ы на Ryzen 6000 используют только s2idle (Modern Standby),
      # S3 недоступен — это прямо подтверждено на странице ArchWiki именно
      # для T14s (AMD) Gen 3 (со слов инженеров Lenovo). Ничего настраивать
      # для этого не нужно, s2idle работает "из коробки".
      # https://wiki.archlinux.org/title/Lenovo_ThinkPad_T14s_(AMD)_Gen_3#Suspend_and_hibernate

      # ПРОВЕРЕНО ПО ВИКИ: страница ArchWiki именно для T14s (AMD) Gen 3
      # прямо пишет, что s2idle "работает из коробки и не вызывает проблем
      # со сном/гибернацией" — про паразитные пробуждения NVMe для этой
      # конкретной модели там ничего нет (в отличие от некоторых других
      # Lenovo-моделей с NVMe, для которых в ядро уже добавлены DMI-квирки
      # thinkpad_acpi/iommu, включающиеся автоматически). Поэтому
      # "nvme.noacpi=1" здесь не форсируется — это общеизвестный фикс для
      # семейства Ryzen 6000 ThinkPad, но не задокументированная
      # необходимость именно для этой модели. Если после сна замечаете
      # повышенный расход заряда (сравните % батареи до/после ночи в S0ix,
      # или `sudo powertop` сразу после пробуждения), раскомментируйте:
      #   "nvme.noacpi=1"
      # Если диск после этого не определяется при загрузке — уберите строку.

      # Известный баг: у части устройств на Rembrandt/Phoenix (в т.ч. этого
      # поколения T14s) экран может зависать/чернеть после сна или
      # гибернации из-за Panel Self Refresh. Официальный фикс с ArchWiki —
      # отключить PSR (жертвуя немного временем автономной работы).
      # Включайте, только если реально сталкиваетесь с чёрным экраном или
      # артефактами после resume:
      #   "amdgpu.dcdebugmask=0x10"
      # https://wiki.archlinux.org/title/Lenovo_ThinkPad_T14s_(AMD)_Gen_3#Display
    ];
    tmp.cleanOnBoot = true;
    # ИСПРАВЛЕНО: extraModprobeConfig = "options thinkpad_acpi fan_control=1";
    # строка реально удалена (в предыдущей правке остался только
    # поясняющий комментарий, а сама строка ошибочно не была убрана).
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

  # ИСПРАВЛЕНО: предыдущая версия этого комментария называла Wi-Fi-карту
  # MediaTek MT7921 — это неверно для T14s (AMD) Gen 3. По странице ArchWiki
  # именно для этой модели, а также по её "родственникам" (P14s/T14 Gen
  # 3-6 AMD) карта — Qualcomm Atheros QCNFA765 (WCN6855, модуль NFA725),
  # работающая через драйвер ath11k. Проверить фактическую карту на вашем
  # экземпляре: `lspci -k | grep -A3 Network`.
  #
  # Задокументированная болячка именно ath11k на этой платформе — зависание
  # процесса resume / потеря Wi-Fi-интерфейса после сна или гибернации.
  # На современных ядрах (6.16+, а у нас и так pkgs.linuxPackages_latest)
  # ArchWiki отмечает, что проблема "не должна больше воспроизводиться" —
  # поэтому автоматический фикс здесь не форсируется. Если всё же ловите
  # зависания при пробуждении или исчезновение Wi-Fi после сна/гибернации,
  # раскомментируйте юниты ниже (перегружают ath11k_pci вокруг sleep.target):
  #
  #   systemd.services.ath11k-suspend = {
  #     description = "Suspend: rmmod ath11k_pci";
  #     before = [ "sleep.target" ];
  #     wantedBy = [ "sleep.target" ];
  #     serviceConfig = {
  #       Type = "oneshot";
  #       ExecStart = "${pkgs.kmod}/bin/rmmod ath11k_pci";
  #     };
  #   };
  #   systemd.services.ath11k-resume = {
  #     description = "Resume: modprobe ath11k_pci";
  #     after = [ "suspend.target" "suspend-then-hibernate.target" "hibernate.target" "hybrid-sleep.target" ];
  #     wantedBy = [ "suspend.target" "suspend-then-hibernate.target" "hibernate.target" "hybrid-sleep.target" ];
  #     serviceConfig = {
  #       Type = "oneshot";
  #       ExecStart = "${pkgs.kmod}/bin/modprobe ath11k_pci";
  #     };
  #   };
  #
  # https://wiki.archlinux.org/title/Lenovo_ThinkPad_T14s_(AMD)_Gen_3#Network_/_Wi-Fi

  # Если в этой конкретной ревизии T14s стоит сканер отпечатков (опция при
  # заказе, не на всех конфигурациях) — он определяется как libfprint-
  # совместимый Synaptics/Goodix сенсор. Включается отдельно:
  #   services.fprintd.enable = true;
  # затем `fprintd-enroll`; в SDDM/PAM входит через отдельный модуль pam.

  # ИСПРАВЛЕНО: services.xserver.videoDrivers = [ "amdgpu" ]; убрано.
  # Эта опция подключается только через services.xserver.enable, которого
  # нигде нет (чистый Wayland/niri, X-сервер не запускается) — без него она
  # ни на что не влияет. amdgpu и так грузится ядром/udev по PCI ID,
  # hardware.enableRedistributableFirmware уже тянет нужные прошивки.

  # НОВОЕ: тачпад T14s (AMD) Gen 3 — Synaptics SYNA8018 — по умолчанию
  # является источником пробуждения из сна. На практике это означает, что
  # ноутбук может выходить из s2idle сам по себе от любого касания/вибрации,
  # пока лежит закрытым в сумке (и сажать батарею). Задокументированный
  # фикс с ArchWiki — снять с i2c-устройства тачпада флаг power/wakeup.
  # Если у вашего экземпляра другой контроллер тачпада, замените
  # "i2c-SYNA8018:00" на актуальное имя из:
  #   grep -i touchpad -A1 /proc/bus/input/devices
  # https://wiki.archlinux.org/title/Lenovo_ThinkPad_T14s_(AMD)_Gen_3#Disable_wakeup_from_sleep_on_touchpad_activity
  # ArchWiki для этой модели отдельно предупреждает про прошивку UEFI
  # 0.1.40 (вышла 5 мая 2024) — она вызывала проблемы со сном, ребутом и
  # даже выключением на части экземпляров (похоже на сбой AMD Sensor Fusion
  # Hub). fwupd ниже покажет установленную версию через `fwupdmgr get-devices`
  # — если стоит именно 0.1.40 и есть подобные симптомы, обновитесь на более
  # свежую через fwupd.
  # https://wiki.archlinux.org/title/Lenovo_ThinkPad_T14s_(AMD)_Gen_3#Firmware
  services.fwupd.enable = true;

  # Стабильный путь до датчика k10temp (AMD CPU). Индекс hwmonN у
  # ThinkPad'ов на Ryzen нередко "плавает" между загрузками/обновлениями
  # ядра (зависит от порядка регистрации drivers), поэтому жёстко зашитый
  # /sys/class/hwmon/hwmon6/... — источник тихой поломки thinkfan: сервис
  # не упадёт, но перестанет видеть температуру CPU и будет держать
  # вентилятор на минимуме. Правило ниже держит актуальную симлинку
  # /run/k10temp-hwmon → нужный /sys/class/hwmon/hwmonN независимо от индекса.
  #
  # Второе правило в том же блоке (все extraRules должны быть в одном месте —
  # тип опции lines, но задать её дважды отдельными атрибутами
  # "services.udev.extraRules = ..." в одном и том же файле Nix не даст,
  # это ошибка "attribute already defined") — снимает флаг power/wakeup с
  # тачпада, см. комментарий про SYNA8018 выше.
  services.udev.extraRules = ''
    SUBSYSTEM=="hwmon", ATTR{name}=="k10temp", RUN+="${pkgs.coreutils}/bin/ln -sfn /sys$env{DEVPATH} /run/k10temp-hwmon"
    KERNEL=="i2c-SYNA8018:00", SUBSYSTEM=="i2c", ATTR{power/wakeup}="disabled"
  '';

  # На "живом" `nixos-rebuild switch` (в отличие от холодной перезагрузки)
  # устройство hwmon для k10temp уже существует, поэтому событие `add`,
  # которое запускает правило выше, не происходит просто от перезапуска
  # systemd-udevd — симлинк не создаётся, и thinkfan падает с "no such
  # file", т.к. открывает несуществующий /run/k10temp-hwmon/temp1_input.
  # Заставляем сам thinkfan.service переиграть udev-событие перед стартом —
  # тогда работает одинаково и на switch, и на холодной загрузке.
  systemd.services.thinkfan = {
    wants = [ "systemd-udev-settle.service" ];
    after = [ "systemd-udev-settle.service" ];
    serviceConfig.ExecStartPre = [
      "${pkgs.systemd}/bin/udevadm trigger --action=add --subsystem-match=hwmon"
      "${pkgs.systemd}/bin/udevadm settle"
    ];
  };

  services.thinkfan = {
    enable = true;

    # Собрать thinkfan с поддержкой чтения температуры дисков через S.M.A.R.T.
    smartSupport = true;

    # Источники температуры. По умолчанию thinkfan и так использует
    # /proc/acpi/ibm/thermal — оставляем явно для читаемости и добавляем
    # k10temp (AMD) как дополнительный сенсор через устойчивый symlink выше.
    sensors = [
      {
        type = "hwmon";
        query = "/run/k10temp-hwmon/temp1_input";
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
      [ 2 45 52 ]
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
    # тумблером — для XWayland у него отдельный механизм, xwayland-satellite,
    # который сам подключается опцией programs.niri.xwayland-satellite
    # (включена по умолчанию, см. комментарий в environment.systemPackages).
    # Опция programs.xwayland.enable ставила пакет xorg.xwayland, который
    # niri не использует.
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

  # Сам модуль virtualisation.vmware.host в nixpkgs предупреждает: vmware-vmx
  # конфликтует с Transparent Hugepages ядра и может грузить ядро kcompactd0
  # на 100% при запущенных виртуалках. Если заметите такое в htop/btop при
  # работе VMware — раскомментируйте (действует на всю систему, не только
  # на VMware):
  #   boot.kernelParams = [ "transparent_hugepage=never" ];
  # https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/virtualisation/vmware-host.nix

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

    # ИСПРАВЛЕНО (было "ПРОВЕРИТЬ"): подтверждено — опция
    # programs.niri.xwayland-satellite добавлена в nixpkgs в
    # NixOS/nixpkgs#442948 и включена по умолчанию, когда programs.niri.enable
    # = true (как у нас выше). Модуль сам ставит пакет xwayland-satellite и
    # прописывает его niri, так что явная строка ниже была чистым
    # дублированием — убрана.

    # ИСПРАВЛЕНО (было "ПРОВЕРИТЬ"): подтверждено по исходнику модуля
    # nixpkgs (nixos/modules/virtualisation/vmware-host.nix) —
    # virtualisation.vmware.host.package по умолчанию уже равен
    # pkgs.vmware-workstation. Явная строка ниже была дублированием — убрана.
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
