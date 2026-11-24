{
  description = "Anurag's NixOS Flake Configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    nixpkgs-alt.url = "github:nixos/nixpkgs/nixos-26.05";
    nixpkgs-firmware.url = "github:NixOS/nixpkgs/8ce4ef6cb6f871616146b9fe26d2a5ae594e94fe";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      # Home-manager uses the user/daily channel so that homescal.packages and
      # programs.* come from nixpkgs-alt by default.
      inputs.nixpkgs.follows = "nixpkgs-alt";
    };

    vicinae.url = "github:vicinaehq/vicinae";

    helium-flake = {
      url = "github:oxcl/nix-flake-helium-browser";
      inputs.nixpkgs.follows = "nixpkgs-alt";
    };

    sidra = {
      url = "github:wimpysworld/sidra";
      inputs.nixpkgs.follows = "nixpkgs-alt";
    };

    niri = {
      url = "github:bugeats/niri-flake/7e196a5ce0bf209d3aca844bb31edce5284d6484";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-alt,
      home-manager,
      vicinae,
      helium-flake,
      nixpkgs-firmware,
      sidra,
      niri,
      ...
    }@inputs:
    let
      system = "x86_64-linux";

      core-pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
        overlays = [ helium-flake.overlays.default ];
      };

      alt-pkgs = import nixpkgs-alt {
        inherit system;
        config.allowUnfree = true;
        overlays = [ helium-flake.overlays.default ];
      };
    in
    {
      nixosConfigurations = {
        neko = nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit alt-pkgs core-pkgs inputs; };
          modules = [
            {
              nixpkgs.overlays = [
                helium-flake.overlays.default

                (final: prev: {
                  linux-firmware = nixpkgs-firmware.legacyPackages.${system}.linux-firmware;
                })
              ];
            }
            ./configuration.nix

            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = false;
              home-manager.useUserPackages = true;
              home-manager.backupFileExtension = "backup";
              home-manager.extraSpecialArgs = {
                inherit
                  core-pkgs
                  vicinae
                  helium-flake
                  sidra
                  inputs
                  ;
              };
              home-manager.users.anurag = import ./home.nix;
            }
          ];
        };
      };
    };
}
