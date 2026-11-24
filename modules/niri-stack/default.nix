{ lib, inputs, config, ... }:

{
  imports = [
    inputs.niri.nixosModules.niri
    ./compositor.nix
    ./personal-launcher.nix
    ./waybar.nix
    ./notifications.nix
    ./lock.nix
    ./packages.nix
  ];

  options.niriStack.enable = lib.mkEnableOption "the niri desktop stack (compositor, shell, waybar, lockscreen)";

  config = lib.mkIf config.niriStack.enable {
    # GNOME stays enabled; this merely registers a Niri session at GDM.
    programs.niri.enable = true;
  };
}
