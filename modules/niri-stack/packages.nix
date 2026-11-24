# Only the runtime deps the migrated shell needs; no bulk copy of donor packages.
{ config, lib, pkgs, ... }:

lib.mkIf config.niriStack.enable {
  environment.systemPackages = with pkgs; [
    swaylock
    swayidle
    swayosd
    wlogout
    grim
    slurp
    wbg
    xwayland-satellite
    brightnessctl
    playerctl
    wlsunset
    polkit_gnome
    tumbler
  ];
}
