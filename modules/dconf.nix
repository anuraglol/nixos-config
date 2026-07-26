{ ... }:
{
  dconf.settings = {
    "org/gnome/desktop/sound" = {
      event-sounds = false;
      feedback-sound = false;
      theme-name = "";
    };
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      cursor-theme = "Bibata-Modern-Ice";
      cursor-size = 20;
      document-font-name = "JetBrains Mono 12";
      font-hinting = "full";
      font-name = "JetBrains Mono 11";
      icon-theme = "Adwaita";
      monospace-font-name = "JetBrains Mono 11";
      text-scaling-factor = 0.98;
    };

    "org/gnome/nautilus/preferences" = {
      default-folder-viewer = "icon-view";
    };

    "org/gtk/gtk4/settings/file-chooser" = {
      show-hidden = false;
      sort-directories-first = false;
      window-size = [ 900 600 ];
    };
    "org/gtk/settings/file-chooser" = {
      bookmarks = [ "file:///data data" ];
      date-format = "regular";
      location-mode = "path-bar";
      show-hidden = false;
      show-size-column = true;
      show-type-column = true;
      sidebar-width = 189;
      sort-column = "name";
      sort-directories-first = false;
      sort-order = "ascending";
      type-format = "category";
      window-size = [ 900 600 ];
    };

    "org/gnome/desktop/wm/preferences" = {
      button-layout = ":";
    };
  };
}
