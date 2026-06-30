{ pkgs, lib, ... }:

# System-level Sway. This only *adds* a "Sway" Wayland session to GDM so you can
# pick it at login. GNOME stays exactly as-is; nothing here touches it.
{
  programs.sway = {
    enable = true;
    wrapperFeatures.gtk = true;
    extraPackages = with pkgs; [
      swayidle # idle handling
      grim # screenshots
      slurp # region select for screenshots
      wl-clipboard # wl-copy / wl-paste
      brightnessctl # screen brightness keys
      playerctl # media keys
    ];
  };

  # Let hyprlock authenticate against your password (without this PAM entry the
  # lock screen can never be unlocked).
  security.pam.services.hyprlock = { };

  # Screen-share / portal support for wlroots compositors (alongside the gtk
  # portal already configured for GNOME).
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-wlr ];

  # Qt apps: prefer the Wayland backend so they honour the compositor's
  # fractional scale (1.5) instead of rendering tiny under XWayland — that was
  # why qBittorrent showed up at 1x. xcb stays as a fallback for any Qt app
  # that misbehaves on Wayland. (qtwayland is already in the Qt closure, the
  # apps just need to be told to use it.) Harmless under GNOME Wayland too.
  environment.sessionVariables.QT_QPA_PLATFORM = "wayland;xcb";

  # swayosd (volume/brightness OSD, enabled per-user in home-manager) controls
  # the backlight by writing sysfs directly — unlike brightnessctl, which fell
  # back to logind. So grant the `video` group write access to the backlight
  # and put the user in it. (mkAfter merges with the rules in hardware.nix.)
  users.users.anurag.extraGroups = [ "video" ];
  services.udev.extraRules = lib.mkAfter ''
    ACTION=="add", SUBSYSTEM=="backlight", RUN+="${pkgs.coreutils}/bin/chgrp video /sys/class/backlight/%k/brightness", RUN+="${pkgs.coreutils}/bin/chmod g+w /sys/class/backlight/%k/brightness"
  '';
}
