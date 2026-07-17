{
  description = "NixOS configuration with Niri and Noctalia";

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
      url = "github:noctalia-dev/noctalia";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Даёт NixOS- и home-manager-модули для niri (programs.niri.settings,
    # используемый в home.nix, — это опция из этого флейка, а не из nixpkgs).
    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, disko, niri, ... }@inputs: {
    formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixfmt-rfc-style;

    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";

      specialArgs = { inherit inputs; };

      modules = [
        disko.nixosModules.disko
        niri.nixosModules.niri
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
            extraSpecialArgs = { inherit inputs; };
            sharedModules = [ niri.homeModules.niri ];
            users.tahara = import ./home.nix;
          };
        }
      ];
    };
  };
}
