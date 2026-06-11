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
    ./modules/git.nix
  ];

  home.username = "anurag";
  home.homeDirectory = "/home/anurag";
  home.stateVersion = "25.11";

  programs.home-manager.enable = true;
  # programs.kitty.enable = true; # required for the default Hyprland config
  # wayland.windowManager.hyprland.enable = true; # enable Hyprland
  # home.sessionVariables.NIXOS_OZONE_WL = "1";

  # wayland.windowManager.hyprland.settings = {
  #   "$mod" = "SUPER";
  #   bind = [
  #     "$mod, Q, exec, kitty"
  #     "$mod, F, exec, firefox"
  #   ]
  #   ++ (builtins.concatLists (
  #     builtins.genList (
  #       i:
  #       let
  #         ws = i + 1;
  #       in
  #       [
  #         "$mod, code:1${toString i}, workspace, ${toString ws}"
  #         "$mod SHIFT, code:1${toString i}, movetoworkspace, ${toString ws}"
  #       ]
  #     ) 9
  #   ));
  # };
}
