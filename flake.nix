{
  description = "Anurag's NixOS Flake Configuration";

  inputs = {
    # 1. Your core system stays on the stable branch
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05"; # Or "nixos-24.11" depending on your current system version

    # 2. Add an explicit input for the unstable packages
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs"; # Keeps HM aligned with your core system package tree
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
              home.stateVersion = "25.05"; # Match your stable system target
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
