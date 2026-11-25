{ lib, ... }:

{
  # Omanix is the desktop session; there is no GNOME session to fall back to.
  omanix = {
    enable = true;
    theme = "vitesse-dark";

    # Wallpaper used by the Omanix shell. Keep it inside the flake so pure
    # evaluation can copy it into the store.
    wallpaperOverride = ../assets/love-zato.png;

    # Ly is the greeter, so don't install Omanix's SDDM theme.
    login.enable = false;

    # Already configured in this flake; don't let Omanix take them over.
    steam.enable = false;
    docker.enable = false;
    sunshine.enable = false; # also keeps services.avahi untouched
  };

  # Make the Hyprland/Omanix session available in Ly. GNOME is not installed.
  programs.hyprland.enable = true;

  # NixOS' wayland-session module declares a swaylock PAM service by default.
  # This setup never runs swaylock: Omanix locks through the Quickshell PAM
  # plugin, and the disabled Niri fallback uses hyprlock. Remove the stray
  # swaylock PAM service and keep a hyprlock PAM service available instead.
  security.pam.services.swaylock.enable = lib.mkForce false;
  security.pam.services.hyprlock = { };
}
