{ config, pkgs, lib, options, ... }:
let
  personalLauncher = config.programs.personalLauncher;
  swayosd = lib.getExe' pkgs.swayosd "swayosd-client";
in
lib.mkIf config.niriStack.enable {
  # NOTE: donor's niri-translucency.kdl (`background-effect`) is omitted: the
  # niri version in nixos-26.05 (25.08) rejects that node. Re-add once niri is
  # upgraded to a version that supports background-effect rules.
  home-manager.users.anurag.programs.niri.settings = {
    binds = {
      "Mod+Return".action.spawn = "kitty";
      "Mod+W".action.close-window = [ ];
      "Mod+F".action.fullscreen-window = [ ];
      "Mod+Shift+Space" = {
        action.toggle-window-floating = [ ];
        repeat = false;
      };
      "Mod+Shift+E".action.quit.skip-confirmation = true;

      "Mod+Space" = {
        repeat = false;
        action.spawn =
          if personalLauncher.enable then [ (lib.getExe personalLauncher.package) "toggle" ]
          else [ "vicinae" "toggle" ];
      };
      "Mod+C".action.spawn = [ "zeditor" "/home/anurag/Documents/nixos-config" ];
      "Mod+B".action.spawn = [ "helium" ];
      "Mod+S".action.spawn = [ "flatpak" "run" "com.spotify.Client" ];
      "Mod+E".action.spawn = [ "nautilus" ];
      "Mod+V".action.spawn = [ "vicinae" "vicinae://launch/clipboard/history" ];

      # Vim-style focus, matching the user's archived config.
      "Mod+H".action.focus-column-left = [ ];
      "Mod+J".action.focus-window-or-workspace-down = [ ];
      "Mod+K".action.focus-window-or-workspace-up = [ ];
      "Mod+semicolon".action.focus-column-right = [ ];
      "Mod+Left".action.focus-column-left = [ ];
      "Mod+Down".action.focus-window-or-workspace-down = [ ];
      "Mod+Up".action.focus-window-or-workspace-up = [ ];
      "Mod+Right".action.focus-column-right = [ ];
      "Mod+Shift+H".action.move-column-left = [ ];
      "Mod+Shift+J".action.move-window-down = [ ];
      "Mod+Shift+K".action.move-window-up = [ ];
      "Mod+Shift+semicolon".action.move-column-right = [ ];
      "Mod+Shift+Left".action.move-column-left = [ ];
      "Mod+Shift+Down".action.move-window-down = [ ];
      "Mod+Shift+Up".action.move-window-up = [ ];
      "Mod+Shift+Right".action.move-column-right = [ ];

      "Mod+Equal".action.set-column-width = "+10%";
      "Mod+Minus".action.set-column-width = "-10%";

      "Mod+1".action.focus-workspace = 1;
      "Mod+2".action.focus-workspace = 2;
      "Mod+3".action.focus-workspace = 3;
      "Mod+4".action.focus-workspace = 4;
      "Mod+5".action.focus-workspace = 5;
      "Mod+6".action.focus-workspace = 6;
      "Mod+7".action.focus-workspace = 7;
      "Mod+8".action.focus-workspace = 8;
      "Mod+9".action.focus-workspace = 9;
      "Mod+0".action.focus-workspace = 10;
      "Mod+Shift+1".action.move-window-to-workspace = 1;
      "Mod+Shift+2".action.move-window-to-workspace = 2;
      "Mod+Shift+3".action.move-window-to-workspace = 3;
      "Mod+Shift+4".action.move-window-to-workspace = 4;
      "Mod+Shift+5".action.move-window-to-workspace = 5;
      "Mod+Shift+6".action.move-window-to-workspace = 6;
      "Mod+Shift+7".action.move-window-to-workspace = 7;
      "Mod+Shift+8".action.move-window-to-workspace = 8;
      "Mod+Shift+9".action.move-window-to-workspace = 9;
      "Mod+Shift+0".action.move-window-to-workspace = 10;

      "Mod+L".action.spawn = [ (lib.getExe pkgs.swaylock) "-f" "--color" "191724ff" ];
      "Mod+M".action.spawn = [ (lib.getExe pkgs.wlogout) "--protocol" "layer-shell" ];

      "Print".action.spawn = [ "sh" "-c" "grim - | wl-copy -t image/png" ];
      "Mod+Shift+S".action.spawn = [ "sh" "-c" "grim -g \"$(slurp)\" - | wl-copy -t image/png" ];

      "XF86AudioRaiseVolume".action.spawn = [ swayosd "--output-volume" "raise" ];
      "XF86AudioLowerVolume".action.spawn = [ swayosd "--output-volume" "lower" ];
      "XF86AudioMute".action.spawn = [ swayosd "--output-volume" "mute-toggle" ];
      "XF86AudioMicMute".action.spawn = [ swayosd "--input-volume" "mute-toggle" ];
      "XF86AudioPlay".action.spawn = [ "playerctl" "play-pause" ];
      "XF86AudioNext".action.spawn = [ "playerctl" "next" ];
      "XF86AudioPrev".action.spawn = [ "playerctl" "previous" ];

      "XF86MonBrightnessUp" = {
        allow-when-locked = true;
        action.spawn = [ (lib.getExe pkgs.brightnessctl) "--class=backlight" "set" "5%+" ];
      };
      "XF86MonBrightnessDown" = {
        allow-when-locked = true;
        action.spawn = [ (lib.getExe pkgs.brightnessctl) "--class=backlight" "set" "5%-" ];
      };

      "Mod+WheelScrollDown" = { action.focus-column-right = [ ]; cooldown-ms = 10; };
      "Mod+WheelScrollUp" = { action.focus-column-left = [ ]; cooldown-ms = 10; };
      "Mod+Shift+WheelScrollDown" = { action.move-column-right = [ ]; cooldown-ms = 10; };
      "Mod+Shift+WheelScrollUp" = { action.move-column-left = [ ]; cooldown-ms = 10; };
    };

    input.touchpad = {
      natural-scroll = true;
      tap = true;
      dwt = true;
      accel-speed = -0.3;
    };
    input.mouse = {
      accel-profile = "flat";
      accel-speed = 0.107296;
    };
    cursor = {
      theme = "Bibata-Modern-Ice";
      size = 20;
    };

    prefer-no-csd = true;
    layout.gaps = 5;
    layout.border = {
      enable = true;
      width = 2;
      active.color = "#c4a7e7";
      inactive.color = "#6e6a86";
    };
    animations = {
      enable = true;
      slowdown = 0.8;
      window-open.kind.spring = { damping-ratio = 0.85; epsilon = 0.01; stiffness = 400; };
      window-close.kind.spring = { damping-ratio = 0.85; epsilon = 0.01; stiffness = 400; };
      window-movement.kind.spring = { damping-ratio = 0.85; epsilon = 0.01; stiffness = 400; };
      window-resize.kind.spring = { damping-ratio = 0.85; epsilon = 0.01; stiffness = 400; };
      workspace-switch.kind.spring = { damping-ratio = 0.85; epsilon = 0.01; stiffness = 400; };
    };

    window-rules = [
      {
        geometry-corner-radius.top-left = 8.0;
        geometry-corner-radius.top-right = 8.0;
        geometry-corner-radius.bottom-left = 8.0;
        geometry-corner-radius.bottom-right = 8.0;
        clip-to-geometry = true;
      }
      {
        matches = [ { app-id = "^kitty$"; } ];
        default-column-width.proportion = 0.6;
      }
      {
        matches = [ { app-id = "org.gnome.Nautilus"; } ];
        open-floating = true;
      }
      {
        matches = [ { app-id = "org.gnome.Loupe"; } ];
        open-floating = true;
      }
      {
        matches = [ { app-id = "pavucontrol"; } ];
        open-floating = true;
      }
    ];

    spawn-at-startup = [
      { argv = [ "waybar" ]; }
      { argv = [ (lib.getExe pkgs.wbg) "-s" "/home/anurag/.config/background" ]; }
    ] ++ lib.optional personalLauncher.enable { argv = [ (lib.getExe personalLauncher.package) "start" ]; };
  };
}
