{
  description = "Anurag's NixOS Flake Configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    nixpkgs-alt.url = "github:nixos/nixpkgs/nixos-26.05";
    nixpkgs-firmware.url = "github:NixOS/nixpkgs/8ce4ef6cb6f871616146b9fe26d2a5ae594e94fe";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      # Home-manager uses the user/daily channel so that home.packages and
      # programs.* come from nixpkgs-alt by default.
      inputs.nixpkgs.follows = "nixpkgs-alt";
    };

    vicinae.url = "github:vicinaehq/vicinae";
    helium-flake = {
      url = "github:oxcl/nix-flake-helium-browser";
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
          specialArgs = { inherit alt-pkgs core-pkgs; };
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
              # Home-manager uses the user/daily channel by default, so
              # everything declared under home.packages / programs.* comes from
              # nixpkgs-alt and can be updated independently of the core system.
              home-manager.useGlobalPkgs = false;
              home-manager.useUserPackages = true;
              home-manager.backupFileExtension = "backup";
              home-manager.extraSpecialArgs = {
                inherit
                  core-pkgs
                  vicinae
                  helium-flake
                  ;
              };
              home-manager.users.anurag = import ./home.nix;
            }
          ];
        };
      };
    };
}
