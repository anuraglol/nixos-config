{
  description = "Anurag's NixOS Flake Configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    vicinae.url = "github:vicinaehq/vicinae";
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-unstable,
      home-manager,
      vicinae,
      ...
    }@inputs:
    let
      system = "x86_64-linux";

      unstable-pkgs = import nixpkgs-unstable {
        inherit system;
        config.allowUnfree = true;
      };
    in
    {
      nixosConfigurations = {
        neko = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            ./configuration.nix

            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.backupFileExtension = "backup";
              home-manager.extraSpecialArgs = { inherit unstable-pkgs vicinae; };
              # Point this directly to your separate home.nix config file
              home-manager.users.anurag = import ./home.nix;
            }
            {
              _module.args = { inherit unstable-pkgs; };
            }
          ];
        };
      };
    };
}
