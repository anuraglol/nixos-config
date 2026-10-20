# Channel architecture

This flake splits packages across two independent Nixpkgs inputs so the
**core system** can stay frozen while **daily/user packages** roll forward.

## Inputs

| Input | Branch | Purpose | Update frequency |
|---|---|---|---|
| `nixpkgs` | `nixos-26.05` | Stable-est core: kernel, systemd, drivers, system services, core libraries | Rarely |
| `nixpkgs-alt` | `nixos-26.05` | User/daily channel: desktop apps, browsers, editors, dev tools, games | Often |
| `nixpkgs-firmware` | pinned rev | Linux firmware, locked to a single commit | Never |

Both channels point at the same stable branch right now, but they are **separate
flake inputs**. That means they can be updated independently.

## How the split is wired

### System config → `nixpkgs` (core)

`configuration.nix`, `hardware-configuration.nix`, and the NixOS modules under
`modules/hardware.nix`, `modules/greeter.nix`, etc. use the system `pkgs`, which
comes from `nixpkgs`.

If a system-level program is also user-facing (Firefox, Steam, Yazi), its
package is explicitly overridden to come from the alt channel:

```nix
# configuration.nix
programs.firefox.package = alt-pkgs.firefox;
programs.yazi.package    = alt-pkgs.yazi;
programs.steam.package   = alt-pkgs.steam;
```

### Home-manager → `nixpkgs-alt` (user)

Home-manager is configured to use `nixpkgs-alt` by default:

```nix
# flake.nix
home-manager = {
  url = "github:nix-community/home-manager/release-26.05";
  inputs.nixpkgs.follows = "nixpkgs-alt";
};
```

And in the NixOS module:

```nix
home-manager.useGlobalPkgs = false;
home-manager.useUserPackages = true;
home-manager.users.anurag = import ./home.nix;
```

This means `pkgs` inside `home.nix` and every imported home-manager module
(`modules/packages.nix`, `modules/kitty.nix`, `modules/niri.nix`, etc.) refers
to the **alt** channel by default.

`core-pkgs` is also passed through as an extra special arg, in case a home
module needs to pull something from the frozen core explicitly.

### Overlays

The `helium` browser comes from `helium-flake`. Its overlay is applied to both
channels so `pkgs.helium` works in home-manager and `core-pkgs.helium` works
wherever `core-pkgs` is used. The firmware overlay is only applied to the
system channel.

## Files and what they use

| File | Default `pkgs` source | Notes |
|---|---|---|
| `configuration.nix` | core (`nixpkgs`) | System-wide services, programs, fonts, portals |
| `modules/hardware.nix` | core | Kernel, graphics, firmware, ACPI rules |
| `modules/greeter.nix` | core | Display manager |
| `home.nix` | alt (`nixpkgs-alt`) | Home-manager entrypoint |
| `modules/packages.nix` | alt | All `home.packages` |
| `modules/kitty.nix` | alt | Terminal config |
| `modules/zed-editor.nix` | alt | Editor config |
| `modules/niri.nix` | alt | Compositor config + autostart |
| `modules/waybar.nix` | alt | Bar config |
| `modules/fish.nix` | alt | Shell config |
| `modules/git.nix` | alt | Git/delta config |
| `modules/mpv.nix` | alt | Media player config |
| `modules/dconf.nix` | alt | GNOME/dconf settings |

## Update commands

```bash
# Update only the user/daily channel (safe, do this often)
nix flake update nixpkgs-alt

# Update only the core system channel (do this rarely, after reading changelog)
nix flake update nixpkgs

# Update the pinned firmware (only if you intentionally want a newer firmware)
nix flake lock --update-input nixpkgs-firmware

# Update everything at once (not recommended for daily use)
nix flake update
```

After updating, rebuild as usual:

```bash
sudo nixos-rebuild switch --flake ~/Documents/nixos-config#neko
```

## Adding a new package

### Daily/user app

Put it in `modules/packages.nix` (or the relevant home module). Use `pkgs.*`,
which resolves to `nixpkgs-alt`:

```nix
home.packages = with pkgs; [
  firefox
  zed-editor
  my-new-app
];
```

### Core/system tool

Put it in `configuration.nix` `environment.systemPackages` (or the relevant
NixOS module). Use `pkgs.*`, which resolves to `nixpkgs`:

```nix
environment.systemPackages = with pkgs; [
  vim
  git
  some-core-tool
];
```

### Mixing channels in a module

If a home module needs a package from the frozen core, use `core-pkgs`:

```nix
{ pkgs, core-pkgs, ... }:
{
  home.packages = [ core-pkgs.some-stable-thing ];
}
```

If a system module needs a package from the rolling alt channel, use
`alt-pkgs`:

```nix
{ pkgs, alt-pkgs, ... }:
{
  programs.some-app.package = alt-pkgs.some-app;
}
```

## Why not `nixpkgs-unstable`?

`nixpkgs-unstable` was removed from the flake. The goal is **independent update
cadence**, not bleeding-edge packages. Both channels stay on the same stable
branch, so you get the stability of stable NixOS with the flexibility of
updating only the apps you touch every day.

If you later want a specific package newer than what stable offers, the options
are:

1. Pin that single package to a newer `nixpkgs` commit via its own flake input.
2. Override the package's `src` manually.
3. Temporarily move just that package to a small third input.

See the older sections below for per-package pinning examples if you ever need
them.

---

## Appendix: per-package pinned inputs (optional)

If one day you need *one* package newer than stable while keeping everything
else frozen, add a dedicated input:

```nix
inputs = {
  nixpkgs-firefox.url = "github:nixos/nixpkgs/somecommit";
};
```

Then overlay it:

```nix
(final: prev: {
  firefox = inputs.nixpkgs-firefox.legacyPackages.${system}.firefox;
})
```

Update only that input:

```bash
nix flake lock --update-input nixpkgs-firefox
```

This is high-maintenance, so only use it for one or two packages.
