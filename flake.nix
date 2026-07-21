{
  description = "NixOS configuration with Niri and Noctalia";

  # Кэш niri.cachix.org сам включается модулем niri-flake для обычных
  # nixos-rebuild, но НЕ успевает подействовать на самой первой сборке при
  # nixos-install (система ещё не переключена, чтобы применить nix.settings).
  # Этот блок читает сама команда `nix`, поэтому кэш работает и на установке —
  # но nix спросит подтверждение (или нужен флаг --accept-flake-config).
  nixConfig = {
    extra-substituters = [
		"https://cache.nixos.org"
		"https://noctalia.cachix.org"
		"https://prismlauncher.cachix.org"
	];
    extra-trusted-public-keys = [
		"cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
		"noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
		"prismlauncher.cachix.org-1:9/n/FGyABA2jLUVfY+DEp4hKds/rwO+SCOtbOkDzd+c="
	];
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

  outputs = { nixpkgs, home-manager, disko, prismlauncher, ... }@inputs: {
    formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixfmt-rfc-style;

    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";

      specialArgs = { inherit inputs; };

      modules = [
        disko.nixosModules.disko
        ./disko.nix
        ./configuration.nix
	(
	  { pkgs, ... }:
	  { environment.systemPackages = [ prismlauncher.packages.${pkgs.system}.prismlauncher ]; }
	)
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
