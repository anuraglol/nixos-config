### Option 1: Two stable inputs (cleanest)

Have one frozen stable input for the core system, and another stable input for your daily packages. Both point to the same stable branch, but  
you update them independently.

```nix
  {
    inputs = {
      # Frozen base system
      nixpkgs-core.url = "github:nixos/nixpkgs/nixos-24.11";

      # Daily packages — same stable branch, updated on its own schedule
      nixpkgs-daily.url = "github:nixos/nixpkgs/nixos-24.11";

      home-manager = {
        url = "github:nix-community/home-manager/release-24.11";
        inputs.nixpkgs.follows = "nixpkgs-core";
      };
    };

    outputs = { self, nixpkgs-core, nixpkgs-daily, home-manager, ... }@inputs:
      let
        system = "x86_64-linux";
        daily-pkgs = import nixpkgs-daily { inherit system; config.allowUnfree = true; };
      in
      {
        nixosConfigurations.neko = nixpkgs-core.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit daily-pkgs; };
          modules = [
            ./configuration.nix
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.extraSpecialArgs = { inherit daily-pkgs; };
              home-manager.users.anurag = import ./home.nix;
            }
          ];
        };
      };
  }
```

Then in home.nix/configuration.nix:

```nix
  { config, pkgs, daily-pkgs, ... }:

  {
    # Core/frozen stuff uses pkgs
    services.postgresql.package = pkgs.postgresql_16;

    # Daily stuff uses daily-pkgs
    programs.firefox.package = daily-pkgs.firefox;
    home.packages = with daily-pkgs; [
      zed-editor
      kitty
      telegram-desktop
    ];
  }
```

Update commands:

```bash
  nix flake update nixpkgs-daily    # only daily packages move
  nix flake update nixpkgs-core     # only when you want the big system bump
  nix flake update                  # updates everything
```

This gives you the stability you want, plus independent update schedules.

────────────────────────────────────────────────────────────────────────────────

### Option 2: Per-package pinned inputs (most control)

If you truly want only specific packages to update and everything else frozen, pin each daily package to its own nixpkgs commit:

```nix
  {
    inputs = {
      nixpkgs-core.url = "github:nixos/nixpkgs/nixos-24.11";
      nixpkgs-firefox.url = "github:nixos/nixpkgs/somecommit";
      nixpkgs-zed.url = "github:nixos/nixpkgs/somecommit";
    };
  }
```

Then overlay them in:

```nix
  (final: prev: {
    firefox = inputs.nixpkgs-firefox.legacyPackages.${system}.firefox;
    zed-editor = inputs.nixpkgs-zed.legacyPackages.${system}.zed-editor;
  })
```

This is tedious if you have many daily packages, but it's the only way to say "only Firefox updates, nothing else."

────────────────────────────────────────────────────────────────────────────────

### Option 3: Manual package version overrides (not recommended for many)

For a few packages, you can override the source directly:

```nix
  pkgs.firefox.overrideAttrs (old: {
    version = "132.0";
    src = pkgs.fetchurl {
      url = "...";
      hash = "...";
    };
  })
```

This is high-maintenance. You have to track versions and hashes yourself. Only worth it for one or two things.

────────────────────────────────────────────────────────────────────────────────

### Bottom line

Nix can't do "update only these packages" natively. The granularity is the flake input. So the practical options are:

┌──────────────────────────────────┬────────┬───────────────────────────────┐  
│ Approach │ Effort │ Granularity │  
├──────────────────────────────────┼────────┼───────────────────────────────┤  
│ Two stable inputs (core + daily) │ Low │ "daily group" vs "core group" │  
├──────────────────────────────────┼────────┼───────────────────────────────┤  
│ Per-package pinned inputs │ Medium │ Per package │  
├──────────────────────────────────┼────────┼───────────────────────────────┤  
│ Manual overrideAttrs │ High │ Per package, fully custom │  
└──────────────────────────────────┴────────┴───────────────────────────────┘

If you want, I can refactor your flake to use two stable inputs (nixpkgs-core frozen, nixpkgs-daily rolling within stable) and move your daily
apps into the daily group. That's usually the sweet spot.
