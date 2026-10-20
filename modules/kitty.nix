{ pkgs, ... }:

{
  programs.kitty = {
    enable = true;

    font = {
      name = "JetBrains Mono";
      size = 11;
    };

    settings = {
      bold_font = "JetBrains Mono Bold";
      window_padding_width = 10;

      background = "#121212";
      foreground = "#dbd7ca";
      selection_background = "#333333";
      selection_foreground = "#dbd7ca";
      cursor = "#dbd7ca";
      cursor_text_color = "#121212";

      color0 = "#121212";
      color1 = "#cb7676";
      color2 = "#4d9375";
      color3 = "#e6cc77";
      color4 = "#6394bf";
      color5 = "#d9739f";
      color6 = "#5eaab5";
      color7 = "#dbd7ca";

      color8 = "#758575";
      color9 = "#cb7676";
      color10 = "#4d9375";
      color11 = "#e6cc77";
      color12 = "#6394bf";
      color13 = "#d9739f";
      color14 = "#5eaab5";
      color15 = "#dbd7ca";
    };
  };
}
