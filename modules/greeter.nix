{ ... }:

{
  # TUI greeter. Runs on a bare TTY and lists every NixOS session
  # (Niri, Hyprland, Sway, GNOME if re-enabled, etc.).
  services.displayManager.ly.enable = false;
}
