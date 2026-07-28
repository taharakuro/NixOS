{ lib, pkgs, ... }:

{
  # hardware-configuration.nix появляется только после установки на
  # конкретное железо (nixos-generate-config на целевой машине). Условный
  # импорт нужен, чтобы disko мог вычислить disko.devices из этого же
  # флейка ещё ДО того, как этот файл закоммичен в репозиторий — иначе
  # вычисление всей конфигурации падает с "file not found" на самом первом
  # шаге (партиционировании), когда файла ещё физически не существует.
  #
  # Остальная конфигурация разложена по темам — так проще найти нужную
  # опцию и не путать «личное» (tor.nix — реальные мосты) с общим:
  #   laptop.nix         — специфика именно этого железа (ThinkPad, AMD,
  #                         вентилятор, SSD)
  #   desktop.nix         — Wayland-сессия: niri, SDDM, XDG-порталы,
  #                         звук, Secret Service, шрифты
  #   gaming.nix          — Steam, Wine, PrismLauncher
  #   virtualisation.nix  — Docker, VMware
  #   packages.nix        — приложения без собственных системных опций
  #   tor.nix             — privoxy + Tor SOCKS для отдельных доменов
  imports = [
    ./tor.nix
    ./laptop.nix
    ./desktop.nix
    ./gaming.nix
    ./virtualisation.nix
    ./packages.nix
  ] ++ lib.optional (builtins.pathExists ./hardware-configuration.nix) ./hardware-configuration.nix;

  system.stateVersion = "26.05";

  nixpkgs.config.allowUnfree = true;

  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      # не ждать по 15 секунд на каждую мёртвую попытку до зеркал
      connect-timeout = 5;

      # nixConfig во flake.nix (extra-substituters/extra-trusted-public-keys)
      # применяется автоматически только для "доверенных" пользователей —
      # для остальных nix каждый раз просит подтверждение либо нужен флаг
      # --accept-flake-config. root и так доверен всегда, поэтому
      # `sudo nixos-rebuild switch` кэши уже использовал. А вот `nix build`,
      # `nix develop`, `home-manager switch` от tahara без sudo — нет.
      # tahara и так в группах wheel (sudo) и docker, то есть уже фактически
      # root-эквивалентен на этой машине, так что добавление в trusted-users
      # не открывает новых возможностей, а просто убирает лишние вопросы.
      trusted-users = [ "root" "@wheel" ];
    };

    # Раньше здесь стоял settings.auto-optimise-store = true — он тоже
    # хардлинкает дубликаты в /nix/store, но делает это синхронно при
    # каждой записи в store (т.е. на каждой сборке), из-за чего сборки
    # могут заметно тормозить. nix.optimise.automatic делает ту же работу
    # по расписанию — это то, что сейчас в первую очередь рекомендует
    # NixOS Wiki ("Storage optimization").
    optimise.automatic = true;

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
    proxy = {
      default = "http://127.0.0.1:8118";
      # "internal.domain" убран — это плейсхолдер прямо из мануала NixOS
      # ("Installing behind a proxy"), скопированный вместе с примером;
      # такого домена у вас нет. Впишите сюда через запятую свои реальные
      # локальные адреса/хосты, если появятся.
      noProxy = "127.0.0.1,localhost,::1";
    };
  };

  time.timeZone = "Europe/Moscow";
  i18n.defaultLocale = "ru_RU.UTF-8";
  console.keyMap = "us";

  boot = {
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;
    # ESP (disko.nix) — всего 512M. Каждое поколение системы кладёт туда
    # свои ядро+initrd; без лимита за много rebuild'ов раздел забьётся и
    # nixos-rebuild однажды упадёт с "no space left on device" на /boot.
    # nix.gc чистит стор-пути, но записи загрузчика подчищаются только
    # при следующем rebuild — этот лимит подчищает их гарантированно.
    loader.systemd-boot.configurationLimit = 10;
    tmp.cleanOnBoot = true;
  };

  # disko.nix уже создаёт и монтирует субволюм @snapshots в /.snapshots —
  # ровно то место, куда snapper кладёт снапшоты для SUBVOLUME = "/".
  # Без этого блока субволюм существовал, но никто в него не писал.
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

  zramSwap.enable = true;

  programs.fish.enable = true;

  users.users.tahara = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" "audio" "docker" ];
    shell = pkgs.fish;
  };
}
