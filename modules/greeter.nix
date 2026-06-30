{ ... }:

# Login greeter. Lives in its own module (not gnome.nix) because the greeter is
# desktop-agnostic — it lists every session NixOS generates, so GNOME and Sway
# both show up. Keeping it separate means GNOME can be ripped out later without
# taking the greeter with it.
#
# ly is a TUI greeter: runs on a bare TTY, no X/GNOME dependency. Pick the
# session (GNOME / Sway) with left/right, type password, enter.
{
  services.displayManager.ly.enable = true;
}
