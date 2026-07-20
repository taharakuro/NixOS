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
	];
    extra-trusted-public-keys = [
		"cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
		"noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
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

    noctalia = {
      url = "github:noctalia-dev/noctalia/cachix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    prismlauncher = {
      url = "github:PrismLauncher/PrismLauncher";
      inputs.nixpkgs.follows = "nixpkgs";
    };
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
            # niri.nixosModules.niri сам подключает свой home-manager
            # модуль каждому HM-пользователю, когда видит home-manager как
            # модуль NixOS — явный sharedModules тут не нужен и вызывал
            # двойное объявление programs.niri.finalConfig.
            extraSpecialArgs = { inherit inputs; };
            users.tahara = import ./home.nix;
          };
        }
      ];
    };
  };
}
