{ pkgs, ... }:

{
  # GNOME temporarily disabled — running Sway only for now. Flip these back to
  # true (and rebuild) to get the GNOME fallback session in ly again. Everything
  # below (excludePackages, xkb) is harmless while disabled.
  services.xserver.enable = false;
  services.desktopManager.gnome.enable = false;

  services.xserver.excludePackages = [ pkgs.xterm ];
  services.gnome.games.enable = false;

  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  environment.gnome.excludePackages = with pkgs; [
    totem
    showtime
    evince
    papers
    gnome-text-editor
    gedit
    baobab
    cheese
    epiphany
    geary
    gnome-calculator
    gnome-calendar
    gnome-characters
    gnome-clocks
    gnome-contacts
    gnome-font-viewer
    gnome-logs
    gnome-maps
    gnome-music
    gnome-weather
    seahorse
    simple-scan
    yelp
    gnome-connections
    gnome-console
    gnome-tour
    gnome-user-docs
    orca
  ];
}
