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

      background = "#1f1d2e";
      foreground = "#e0def4";
      selection_background = "#2f2c40";
      selection_foreground = "#e0def4";
      cursor = "#e0def4";
      cursor_text_color = "#1f1d2e";

      color0 = "#26233a";
      color1 = "#eb6f92";
      color2 = "#31748f";
      color3 = "#f6c177";
      color4 = "#9ccfd8";
      color5 = "#c4a7e7";
      color6 = "#ebbcba";
      color7 = "#e0def4";

      color8 = "#908caa";
      color9 = "#eb6f92";
      color10 = "#31748f";
      color11 = "#f6c177";
      color12 = "#9ccfd8";
      color13 = "#c4a7e7";
      color14 = "#ebbcba";
      color15 = "#e0def4";
    };
  };
}
