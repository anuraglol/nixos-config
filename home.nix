{
  config,
  pkgs,
  unstable-pkgs,
  lib,
  ...
}:
{
  imports = [
    ./modules/packages.nix
    ./modules/dconf.nix
    ./modules/fish.nix
    ./modules/ghostty.nix
    ./modules/fastfetch.nix
    ./modules/zed-editor.nix
    ./modules/kitty.nix
  ];

  home.username = "anurag";
  home.homeDirectory = "/home/anurag";
  home.stateVersion = "25.11";

  programs.home-manager.enable = true;
}
