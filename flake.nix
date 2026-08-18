{
  description = "NixOS configuration with Niri and Noctalia";

  # ИСПРАВЛЕНО: предыдущая версия этого комментария объясняла отсутствие
  # niri.cachix.org тем, что его кэш "сам включается модулем niri-flake" —
  # но niri-flake (sodiboo/niri-flake или аналог) в этом flake нигде не
  # используется как input, niri берётся напрямую из nixpkgs (см.
  # programs.niri.enable в configuration.nix и комментарий в home.nix про
  # отсутствие HM-модуля для niri). Поэтому кэша niri.cachix.org здесь и не
  # должно быть — он просто не нужен, бинарники niri уже собираются и лежат
  # в обычном cache.nixos.org вместе с остальным nixpkgs.
  #
  # extra-substituters/extra-trusted-public-keys ниже (noctalia, prismlauncher)
  # читает сама команда `nix`, поэтому кэш работает и на самой первой сборке
  # при nixos-install (система ещё не переключена, и nix.settings из
  # configuration.nix ещё не применились) — но nix спросит подтверждение
  # (или нужен флаг --accept-flake-config).
  nixConfig = {
    extra-substituters = [
      "https://noctalia.cachix.org"
      "https://prismlauncher.cachix.org"
    ];
    extra-trusted-public-keys = [
      "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
      "prismlauncher.cachix.org-1:9/n/FGyABA2jLUVfY+DEp4hKds/rwO+SCOtbOkDzd+c="
    ];
    # ИСПРАВЛЕНО: cache.nixos.org отсюда убран — он и так входит в
    # substituters по умолчанию на любой стандартной установке NixOS
    # (включая установочный ISO), добавление его как extra-* было чистой
    # редупликацией без эффекта.
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Намеренно БЕЗ inputs.nixpkgs.follows = "nixpkgs" у noctalia и
    # prismlauncher ниже. Ветка /cachix у noctalia и кэш
    # prismlauncher.cachix.org собраны под конкретную ревизию ИХ
    # собственного nixpkgs; если подставить сюда свой nixpkgs (26.05),
    # стор-пути перестанут совпадать с тем, что лежит в кэше — получите
    # промах кэша и локальную сборку Qt/QML с нуля вместо бинарника.
    # Официальный README PrismLauncher прямо предупреждает об этом.
    # Экономия на дублировании nixpkgs в лок-файле того не стоит.
    noctalia.url = "github:noctalia-dev/noctalia/cachix";

    prismlauncher.url = "github:PrismLauncher/PrismLauncher";
  };

  outputs = { nixpkgs, home-manager, disko, ... }@inputs: {
    formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixfmt-rfc-style;

    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";

      specialArgs = { inherit inputs; };

      # ИСПРАВЛЕНО: инлайн-модуль, ставивший prismlauncher прямо здесь,
      # убран — это была единственная "политика" (что ставить), жившая в
      # flake.nix, а не в configuration.nix. Пакет теперь ставится в
      # configuration.nix через inputs.prismlauncher (доступен благодаря
      # specialArgs выше) — рядом со всем остальным списком пакетов.
      modules = [
        disko.nixosModules.disko
        ./disko.nix
        ./configuration.nix
        home-manager.nixosModules.home-manager
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            # чтобы activation не падал, если в $HOME уже лежат обычные
            # (не symlink) дотфайлы, конфликтующие с управляемыми HM
            backupFileExtension = "hm-backup";
            # ВАЖНО: niri здесь НЕ отдельный flake-input (его нет в inputs
            # ниже) — programs.niri.enable в configuration.nix берётся из
            # самого nixpkgs (модуль въехал туда начиная примерно с 25.05).
            # У upstream home-manager своего модуля для niri пока нет
            # (nix-community/home-manager#8700 всё ещё не смёржен), поэтому
            # per-user конфиг niri (config.kdl) сейчас не управляется через
            # HM — sharedModules тут заводить не на что и не нужно. Если
            # захотите декларативный niri-конфиг через HM раньше, чем смёржат
            # PR #8700 — единственный вариант это добавить sodiboo/niri-flake
            # или niri-nix отдельным input'ом (но тогда нужно будет отключить
            # nixpkgs-модуль, они конфликтуют).
            extraSpecialArgs = { inherit inputs; };
            users.tahara = import ./home.nix;
          };
        }
      ];
    };
  };
}
