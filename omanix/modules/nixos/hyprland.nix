{ config, lib, pkgs, ... }:
let
  cfg = config.omanix;

  # Hyprland comes from the user's nixpkgs (binary-cached, Mesa-matched), so
  # Omanix can't pin it. Bump this after testing the generated Lua config
  # against a new Hyprland release.
  # Local integration: our nixos-26.05 pin ships Hyprland 0.55.x.
  testedHyprland = "0.55";
  hyprlandVersion = lib.versions.majorMinor config.programs.hyprland.package.version;
in
{
  config = lib.mkIf cfg.enable {
    warnings = lib.optional (config.programs.hyprland.enable && hyprlandVersion != testedHyprland) ''
      omanix: tested with Hyprland ${testedHyprland}.x, but nixpkgs provides ${config.programs.hyprland.package.version}.
      Expect config errors until Omanix supports it (check `hyprctl configerrors`).
    '';

    # withUWSM = false prevents programs.uwsm.enable from being set,
    # but hyprland-uwsm.desktop is baked into the hyprland package itself
    # (upstream ships it in systemd/hyprland-uwsm.desktop via CMake).
    # We replace the session package with one that only exposes hyprland.desktop.
    # Selecting hyprland-uwsm.desktop causes a kernel DRM master deadlock:
    # Weston holds DRM master while uwsm's async systemd startup races to
    # acquire it, freezing the system with no TTY escape possible.
    programs.hyprland.withUWSM = false;

    # With home-manager.useUserPackages the user profile is built from these
    # paths only; OMANIX_PATH resolves through it.
    environment.pathsToLink = [ "/share/omanix" ];

    # Local integration: programs.hyprland.enable already adds the Hyprland
    # session to GDM, so don't register a duplicate here (and don't replace
    # GNOME's session packages).
  };
}
