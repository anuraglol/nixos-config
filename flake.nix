{
  description = "Anurag's NixOS Flake Configuration";

  inputs = {
    # Core stable system channel
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";

    # Extra channel for un-prefixed unstable apps (like zed-editor)
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    # Explicitly track the matching release branch for Home Manager
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-unstable,
      home-manager,
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
              home-manager.extraSpecialArgs = { inherit unstable-pkgs; };
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
