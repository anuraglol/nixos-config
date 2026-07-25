{
  config,
  pkgs,
  unstable-pkgs,
  vicinae,
  lib,
  inputs,
  ...
}:

let
  # Rosé Pine theme for btop
  # Source: https://github.com/rose-pine/btop
  rosePineBtop = {
    theme = {
      background = "#191724";
      main_bg = "#26233a";
      main_fg = "#e0def4";
      title = "#ebbcba";
      hi_fg = "#f6c177";
      selected_bg = "#31748f";
      selected_fg = "#e0def4";
      inactive_fg = "#6e6a86";
      graph_text = "#908caa";
      proc_misc = "#908caa";
      cpu_box = "#9ccfd8";
      mem_box = "#f6c177";
      net_box = "#c4a7e7";
      proc_box = "#ebbcba";
      div_line = "#6e6a86";
      temp_start = "#31748f";
      temp_mid = "#f6c177";
      temp_end = "#eb6f92";
      cpu_start = "#9ccfd8";
      cpu_mid = "#f6c177";
      cpu_end = "#eb6f92";
      mem_start = "#9ccfd8";
      mem_mid = "#f6c177";
      mem_end = "#eb6f92";
      net_start = "#9ccfd8";
      net_mid = "#f6c177";
      net_end = "#eb6f92";
      free_start = "#31748f";
      free_mid = "#f6c177";
      free_end = "#eb6f92";
      graph_1 = "#9ccfd8";
      graph_2 = "#f6c177";
      text_1 = "#e0def4";
      text_2 = "#908caa";
      text_3 = "#6e6a86";
      cpu_core_1 = "#ebbcba";
      cpu_core_2 = "#f6c177";
      cpu_core_3 = "#9ccfd8";
      cpu_core_4 = "#c4a7e7";
      cpu_core_5 = "#31748f";
      cpu_core_6 = "#eb6f92";
      cpu_core_7 = "#908caa";
      cpu_core_8 = "#6e6a86";
      cpu_core_9 = "#ebbcba";
      cpu_core_10 = "#f6c177";
      cpu_core_11 = "#9ccfd8";
      cpu_core_12 = "#c4a7e7";
      cpu_core_13 = "#31748f";
      cpu_core_14 = "#eb6f92";
      cpu_core_15 = "#908caa";
      cpu_core_16 = "#6e6a86";
      cpu_core_17 = "#ebbcba";
      cpu_core_18 = "#f6c177";
      cpu_core_19 = "#9ccfd8";
      cpu_core_20 = "#c4a7e7";
      cpu_core_21 = "#31748f";
      cpu_core_22 = "#eb6f92";
      cpu_core_23 = "#908caa";
      cpu_core_24 = "#6e6a86";
      cpu_core_25 = "#ebbcba";
      cpu_core_26 = "#f6c177";
      cpu_core_27 = "#9ccfd8";
      cpu_core_28 = "#c4a7e7";
      cpu_core_29 = "#31748f";
      cpu_core_30 = "#eb6f92";
      cpu_core_31 = "#908caa";
      cpu_core_32 = "#6e6a86";
      mem_1 = "#9ccfd8";
      mem_2 = "#f6c177";
      mem_3 = "#eb6f92";
      mem_4 = "#6e6a86";
      mem_5 = "#c4a7e7";
      mem_6 = "#ebbcba";
      mem_7 = "#31748f";
      mem_8 = "#908caa";
      mem_9 = "#e0def4";
      mem_10 = "#26233a";
      net_1 = "#9ccfd8";
      net_2 = "#f6c177";
      net_3 = "#eb6f92";
      net_4 = "#6e6a86";
      net_5 = "#c4a7e7";
      net_6 = "#ebbcba";
      net_7 = "#31748f";
      net_8 = "#908caa";
      net_9 = "#e0def4";
      net_10 = "#26233a";
      proc_1 = "#9ccfd8";
      proc_2 = "#f6c177";
      proc_3 = "#eb6f92";
      proc_4 = "#6e6a86";
      proc_5 = "#c4a7e7";
      proc_6 = "#ebbcba";
      proc_7 = "#31748f";
      proc_8 = "#908caa";
      proc_9 = "#e0def4";
      proc_10 = "#26233a";
    };
  };
in
{
  imports = [
    ./modules/packages.nix
    ./modules/dconf.nix
    ./modules/fish.nix
    ./modules/fastfetch.nix
    ./modules/zed-editor.nix
    ./modules/kitty.nix
    ./modules/git.nix
    ./modules/sway-home.nix
    vicinae.homeManagerModules.default
  ];

  home.username = "anurag";
  home.homeDirectory = "/home/anurag";
  home.stateVersion = "26.05";

  programs.home-manager.enable = true;
  programs.kitty.enable = true;

  programs.btop = {
    enable = true;
    settings = {
      color_theme = "rose-pine";
      theme_background = true;
      truecolor = true;
      vim_keys = true;
    };
  };

  # Place the Rosé Pine theme file in the exact path btop expects.
  xdg.configFile."btop/themes/rose-pine.theme".text =
    lib.generators.toINI { } rosePineBtop;

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
    addKeysToAgent = "yes";
  };

  services.vicinae = {
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
