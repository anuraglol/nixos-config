{ pkgs, ... }:

{
  # Force a real installed dark theme at the source level. Home Manager only
  # writes gtk-theme-name; without the theme package and colorScheme GTK falls
  # back to the light Adwaita/GTK4 default.
#   gtk = {
#     enable = true;
#     colorScheme = "dark";
#     theme = {
#       name = "Adwaita-dark";
#       package = pkgs.gnome-themes-extra;
#     };
#   };
#
#   home.sessionVariables.GTK_THEME = "Adwaita-dark";
#
#   dconf.settings."org/gnome/desktop/interface" = {
#     color-scheme = "prefer-dark";
#     gtk-theme = "Adwaita-dark";
#   };
}
