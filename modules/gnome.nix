{ pkgs, ... }:

{
  services.xserver.enable = true;
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

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
