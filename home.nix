{
  pkgs,
  vicinae,
  helium-flake,
  lib,
  ...
}:

{
  # The user channel allows unfree packages (obsidian, slack, steam, etc.).
  nixpkgs.config.allowUnfree = true;
  nixpkgs.overlays = [ helium-flake.overlays.default ];

  imports = [
    ./modules/packages.nix
    ./modules/dconf.nix
    ./modules/fish.nix
    ./modules/zed-editor.nix
    ./modules/kitty.nix
    ./modules/git.nix
    ./modules/mpv.nix
    ./modules/niri.nix
    vicinae.homeManagerModules.default
  ];

  home.username = "anurag";
  home.homeDirectory = "/home/anurag";
  home.stateVersion = "26.05";

  programs.home-manager.enable = true;
  programs.kitty.enable = true;

  gtk = {
    enable = true;
    gtk3.extraConfig = {
      gtk-decoration-layout = ":";
    };
    gtk4.extraConfig = {
      gtk-decoration-layout = ":";
    };
  };

  programs.btop = {
    enable = true;
    settings = {
      theme_background = true;
      truecolor = true;
      vim_keys = true;
    };
  };

  home.sessionVariables.NIXOS_OZONE_WL = "1";
  # Force GTK apps (incl. Zen/Firefox in its default "auto" mode) to use the
  # xdg-desktop-portal file picker -> the GNOME (pretty GTK4/Nautilus) chooser.
  home.sessionVariables.GTK_USE_PORTAL = "1";

  services.ssh-agent.enable = true;
  programs.ssh = {
    enable = true;
    settings."*" = {
      AddKeysToAgent = "yes";
    };
  };

  home.file.".config/autostart/vicinae.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=Vicinae
    Exec=vicinae server --replace
    Terminal=false
    Icon=vicinae
    Categories=Utility;Accessibility;
    StartupNotify=false
  '';

  programs.vicinae = {
    enable = true;
    package = pkgs.vicinae;
    systemd = {
      enable = true;
      autoStart = true;
      environment = {
        USE_LAYER_SHELL = 1;
      };
    };
    settings = {
      pop_to_root_on_close = true;
      theme = {
        dark = {
          name = "tokyo-night";
          icon_theme = "default";
        };
      };
      launcher_window = {
        opacity = 0.98;
      };
    };
  };
}
