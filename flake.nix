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

    # Local Omanix copy. Pin its transitive Nix inputs to this flake's versions
    # so we don't pull in a second nixpkgs/Home Manager release.
    omanix = {
      url = "path:./omanix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
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
      omanix,
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
            ./modules/omanix.nix
            omanix.nixosModules.default

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
                  omanix
                  ;
              };
              home-manager.users.anurag = import ./home.nix;
            }
          ];
        };
      };
    };
}
