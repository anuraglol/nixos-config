{ pkgs, lib, ... }:

{
  programs.sway = {
    enable = true;
    wrapperFeatures.gtk = true;
    extraPackages = with pkgs; [
      swayidle
      grim
      slurp
      wl-clipboard
      brightnessctl
      playerctl
    ];
  };

  security.pam.services.swaylock = { };

  # Suspend is deliberate: closing the lid is the only thing that enters s2idle
  # (there is no S3 deep sleep on this machine). swayidle intentionally does NOT
  # auto-suspend on idle -- see modules/sway-home.nix. This just makes logind's
  # default lid->suspend behaviour explicit and documents the intent.
  services.logind.settings.Login.HandleLidSwitch = "suspend";

  security.polkit.enable = true;

  services.gnome.gnome-keyring.enable = true;
  security.pam.services.ly.enableGnomeKeyring = true;

  services.gvfs.enable = true;
  services.tumbler.enable = true;

  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-wlr ];

  environment.sessionVariables = {
    QT_QPA_PLATFORM = "wayland;xcb";
    # NOTE: do NOT set QT_SCALE_FACTOR globally. Qt Quick apps (e.g. vicinae)
    # honour Sway's native Wayland fractional-scale (1.5x) themselves, so a
    # global QT_SCALE_FACTOR=1.5 double-scales them to 2.25x. Only qbittorrent
    # (Qt Widgets, ignores Wayland scale) needs the manual factor, and it gets
    # it per-binary via the wrapper in packages.nix.
  };

  users.users.anurag.extraGroups = [ "video" ];
  services.udev.extraRules = lib.mkAfter ''
    ACTION=="add", SUBSYSTEM=="backlight", RUN+="${pkgs.coreutils}/bin/chgrp video /sys/class/backlight/%k/brightness", RUN+="${pkgs.coreutils}/bin/chmod g+w /sys/class/backlight/%k/brightness"
  '';
}
