{ lib, ... }:

{
  # TUI greeter on a bare TTY. It replaces GDM and lists every registered
  # session (Hyprland/Omanix, Niri, etc.) without pulling in a desktop session.
  services.displayManager.ly.enable = true;
  services.displayManager.gdm.enable = lib.mkForce false;
}
