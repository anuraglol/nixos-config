{
  programs.mpv = {
    enable = true;

    config = {
      save-position-on-quit = true;
    };

    bindings = {
      "1" = "set speed 1.0";
      "2" = "set speed 1.25";
      "3" = "set speed 1.5";
      "4" = "set speed 1.75";
      "5" = "set speed 2.0";
      "0" = "set speed 1.0";
    };
  };
}
