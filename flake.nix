{
  description = "Anurag's NixOS Flake Configuration";

  inputs = {
      # Core stable system channel
      nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";

      # Extra channel for un-prefixed unstable apps (like zed-editor)
      nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

      # FIX: Explicitly track the matching release branch for Home Manager
      home-manager = {
        url = "github:nix-community/home-manager/release-25.11";
        inputs.nixpkgs.follows = "nixpkgs";
      };
    };

  outputs = { self, nixpkgs, nixpkgs-unstable, home-manager, ... }@inputs:
  let
    system = "x86_64-linux";

    # Define our unstable packages instance, ensuring it respects unfree licenses if needed
    unstable-pkgs = import nixpkgs-unstable {
      inherit system;
      config.allowUnfree = true;
    };
  in {
    nixosConfigurations = {
      nixos = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          ./configuration.nix

          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.anurag = { pkgs, ... }: {
              home.stateVersion = "25.11"; # Match your stable system target
              programs.home-manager.enable = true;
              home.packages = with pkgs; [];
            };
          }

          # This special block injects "unstable" as an extra parameter
          # that your configuration.nix file can read!
          {
            _module.args = { inherit unstable-pkgs; };
          }
        ];
      };
    };
  };
}
