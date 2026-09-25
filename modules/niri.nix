{ pkgs, lib, ... }:

{
  # Niri itself is enabled in configuration.nix. This module adds the same
  # session support that sway.nix provides (polkit, keyring, lid suspend,
  # backlight permissions, Qt platform, etc.) so Niri works standalone.

  security.pam.services.swaylock = { };
  security.polkit.enable = true;

  services.gnome.gnome-keyring.enable = true;
  security.pam.services.ly.enableGnomeKeyring = true;

  services.gvfs.enable = true;
  services.tumbler.enable = true;

  # Suspend on lid close, same reasoning as in sway.nix.
  services.logind.settings.Login.HandleLidSwitch = "suspend";

  programs.xwayland.enable = true;

  environment.sessionVariables = {
    QT_QPA_PLATFORM = "wayland;xcb";
  };

  users.users.anurag.extraGroups = [ "video" ];
  services.udev.extraRules = lib.mkAfter ''
    ACTION=="add", SUBSYSTEM=="backlight", RUN+="${pkgs.coreutils}/bin/chgrp video /sys/class/backlight/%k/brightness", RUN+="${pkgs.coreutils}/bin/chmod g+w /sys/class/backlight/%k/brightness"
  '';

  environment.systemPackages = with pkgs; [
    swaybg
  ];
}
