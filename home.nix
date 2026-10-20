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

  # SSH agent. Under GNOME, gnome-keyring was the SSH agent and auto-unlocked
  # the (passphrase-protected) key, so git-over-ssh "just worked". Sway has no
  # such thing, leaving SSH_AUTH_SOCK empty and the locked key unusable
  # (git push -> "Permission denied (publickey)"). Run a plain ssh-agent as a
  # user systemd service instead — it sets SSH_AUTH_SOCK=$XDG_RUNTIME_DIR/ssh-agent
  # (a fixed path, picked up by fish via home.sessionVariables) and starts with
  # the user manager, so it isn't subject to the WAYLAND_DISPLAY startup race.
  # addKeysToAgent makes ssh cache the key on first use (one passphrase prompt
  # per login), matching the old auto-unlock feel.
  services.ssh-agent.enable = true;
  programs.ssh = {
    enable = true;
    settings."*" = {
      AddKeysToAgent = "yes";
    };
  };

  # Vicinae is already auto-started via systemd below, but also register it as
  # a GNOME startup app so it shows up in Settings > Startup Applications.
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
