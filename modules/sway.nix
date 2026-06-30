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

  security.pam.services.hyprlock = { };

  security.polkit.enable = true;

  services.gnome.gnome-keyring.enable = true;
  security.pam.services.ly.enableGnomeKeyring = true;

  services.gvfs.enable = true;
  services.tumbler.enable = true;

  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-wlr ];

  environment.sessionVariables.QT_QPA_PLATFORM = "wayland;xcb";

  users.users.anurag.extraGroups = [ "video" ];
  services.udev.extraRules = lib.mkAfter ''
    ACTION=="add", SUBSYSTEM=="backlight", RUN+="${pkgs.coreutils}/bin/chgrp video /sys/class/backlight/%k/brightness", RUN+="${pkgs.coreutils}/bin/chmod g+w /sys/class/backlight/%k/brightness"
  '';
}
