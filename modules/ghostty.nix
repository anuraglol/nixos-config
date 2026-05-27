{ ... }:

{
  programs.ghostty = {
    enable = true;
    enableFishIntegration = true;
    settings = {
      font-family = "JetBrains Mono";
      font-family-bold = "JetBrains Mono Bold";
      font-size = 11;

      window-padding-x = 10;
      window-padding-y = 10;

      background = "#1f1d2e";
      foreground = "#e0def4";
      selection-background = "#2f2c40";
      selection-foreground = "#e0def4";
      cursor-color = "#e0def4";
      cursor-text = "#1f1d2e";
      palette = [
        "0=#26233a"
        "1=#eb6f92"
        "2=#31748f"
        "3=#f6c177"
        "4=#9ccfd8"
        "5=#c4a7e7"
        "6=#ebbcba"
        "7=#e0def4"
        "8=#908caa"
        "9=#eb6f92"
        "10=#31748f"
        "11=#f6c177"
        "12=#9ccfd8"
        "13=#c4a7e7"
        "14=#ebbcba"
        "15=#e0def4"
      ];
    };
  };
}
