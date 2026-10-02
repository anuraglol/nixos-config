{
  config,
  pkgs,
  lib,
  ...
}:

let
  mod = "Mod";
  terminal = "kitty";

  wallpaper = "${config.home.homeDirectory}/.config/background";

  # ─────────────────────────────────────────────────────────────
  # Rosé Pine
  # ─────────────────────────────────────────────────────────────

  base = "#191724";
  surface = "#1f1d2e";
  overlay = "#26233a";
  highlightMed = "#403d52";
  muted = "#6e6a86";
  subtle = "#908caa";
  text = "#e0def4";
  love = "#eb6f92";
  iris = "#c4a7e7";
  foam = "#9ccfd8";
  gold = "#f6c177";

  # Executable paths get unique names so they don't shadow packages
  # inside `home.packages`.
  swaylockBin = pkgs.writeShellScript "niri-swaylock" ''
    exec ${pkgs.swaylock}/bin/swaylock -f --color ${lib.removePrefix "#" base}ff
  '';
  systemctlBin = "${pkgs.systemd}/bin/systemctl";
  swayosdBin = "${pkgs.swayosd}/bin/swayosd-client";

  # ─────────────────────────────────────────────────────────────
  # Screenshots
  # ─────────────────────────────────────────────────────────────

  shotFull = pkgs.writeShellScript "niri-shot-full" ''
    mkdir -p "$HOME/Pictures/Screenshots"

    ${pkgs.grim}/bin/grim - |
      ${pkgs.wl-clipboard}/bin/wl-copy &&
      ${pkgs.libnotify}/bin/notify-send \
        "Screenshot" \
        "Full screen copied to clipboard"
  '';

  shotRegion = pkgs.writeShellScript "niri-shot-region" ''
    mkdir -p "$HOME/Pictures/Screenshots"

    geom=$(${pkgs.slurp}/bin/slurp) || exit 0

    ${pkgs.grim}/bin/grim -g "$geom" - |
      ${pkgs.wl-clipboard}/bin/wl-copy &&
      ${pkgs.libnotify}/bin/notify-send \
        "Screenshot" \
        "Region copied to clipboard"
  '';

  # ─────────────────────────────────────────────────────────────
  # Night light
  # ─────────────────────────────────────────────────────────────

  nightToggle = pkgs.writeShellScript "niri-nightlight-toggle" ''
    if ${pkgs.procps}/bin/pgrep -x wlsunset >/dev/null; then
      ${pkgs.procps}/bin/pkill -x wlsunset
    else
      ${pkgs.wlsunset}/bin/wlsunset \
        -t 3499 \
        -T 3500 \
        >/dev/null 2>&1 &
    fi

    ${pkgs.procps}/bin/pkill -RTMIN+8 waybar || true
  '';

  # ─────────────────────────────────────────────────────────────
  # SwayOSD styling
  # ─────────────────────────────────────────────────────────────

  swayosdStyle = pkgs.writeText "swayosd-style.css" ''
    window {
      border-radius: 0;
      opacity: 0.97;
      border: 2px solid ${highlightMed};
      background-color: ${surface};
    }

    label {
      font-family: 'JetBrains Mono';
      font-size: 11pt;
      color: ${text};
    }

    image {
      color: ${text};
    }

    progressbar {
      border-radius: 0;
    }

    progressbar trough {
      background-color: ${highlightMed};
    }

    progress {
      background-color: ${iris};
    }
  '';

  # ─────────────────────────────────────────────────────────────
  # Lock / suspend
  # ─────────────────────────────────────────────────────────────

  lock = "${swaylockBin}";
  suspend = "${systemctlBin} suspend";

in
{
  imports = [ ./waybar.nix ];

  # Use Niri modules in the shared Waybar config and start it via Niri.
  programs.waybar = {
    systemd.enable = lib.mkForce false;
    settings.mainBar = {
      modules-left = lib.mkForce [
        "niri/workspaces"
        "niri/submap"
      ];
      "niri/workspaces" = lib.mkForce {
        format-icons = {
          "1" = "1";
          "2" = "2";
          "3" = "3";
          "4" = "4";
          "5" = "5";
          "6" = "6";
          "7" = "7";
          "8" = "8";
          "9" = "9";
          "10" = "0";
          active = "󰝥";
          urgent = "󰝥";
        };
        persistent-workspaces = {
          "1" = [ ];
          "2" = [ ];
          "3" = [ ];
          "4" = [ ];
          "5" = [ ];
        };
      };
    };
  };

  # ═══════════════════════════════════════════════════════════════
  # PACKAGES
  # ═══════════════════════════════════════════════════════════════

  home.packages = with pkgs; [
    # Niri
    niri

    # Lock
    swaylock

    # Idle handling
    swayidle

    # Notifications
    libnotify

    # Screenshots
    grim
    slurp
    wl-clipboard

    # OSD
    swayosd

    # Wallpaper
    swaybg

    # Brightness / media
    brightnessctl
    playerctl

    # Night light
    wlsunset

    # Polkit / desktop integration
    polkit_gnome
    gvfs
    tumbler

    # File manager
    nautilus

    # Cursor
    bibata-cursors
  ];

  # ═══════════════════════════════════════════════════════════════
  # WAYLAND ENVIRONMENT
  # ═══════════════════════════════════════════════════════════════

  home.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    GTK_USE_PORTAL = "1";
    QT_QPA_PLATFORM = "wayland;xcb";
  };

  # ═══════════════════════════════════════════════════════════════
  # NIRI
  # ═══════════════════════════════════════════════════════════════

  xdg.configFile."niri/config.kdl".text = ''
    // ╔══════════════════════════════════════════════════════════╗
    // ║                         NIRI                             ║
    // ║                    Rosé Pine setup                       ║
    // ╚══════════════════════════════════════════════════════════╝


    // ─────────────────────────────────────────────────────────
    // Input
    // ─────────────────────────────────────────────────────────

    input {
        keyboard {
        }

        touchpad {
            tap
            natural-scroll
            dwt
            accel-speed -0.55
        }

        mouse {
            accel-profile "flat"
            accel-speed 0.107296
        }
    }


    // ─────────────────────────────────────────────────────────
    // Output
    // ─────────────────────────────────────────────────────────

    output "*" {
        scale 1.5
        background-color "${base}"
    }

    output "eDP-1" {
        scale 1.5
    }


    // Note: fractional scale is set above via `scale 1.5`.


    // ─────────────────────────────────────────────────────────
    // Layout
    // ─────────────────────────────────────────────────────────

    layout {
        gaps 0

        center-focused-column "never"

        preset-column-widths {
            proportion 0.333333
            proportion 0.5
            proportion 0.666667
        }

        default-column-width {
            proportion 1.0
        }

        focus-ring {
            width 1
            active-color "${overlay}"
            inactive-color "${surface}"
        }

        border {
            off
        }
    }


    // ─────────────────────────────────────────────────────────
    // Client decorations
    // ─────────────────────────────────────────────────────────

    prefer-no-csd


    // ─────────────────────────────────────────────────────────
    // Animations
    // ─────────────────────────────────────────────────────────

    animations {
        slowdown 0.7
    }


    // ─────────────────────────────────────────────────────────
    // Startup
    // ─────────────────────────────────────────────────────────

    spawn-at-startup "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"

    spawn-at-startup "${pkgs.systemd}/bin/systemctl" "--user" "restart" "mako.service"

    spawn-at-startup "waybar"

    spawn-at-startup "${pkgs.systemd}/bin/systemctl" "--user" "import-environment" "WAYLAND_DISPLAY" "NIRI_SOCKET" "XDG_CURRENT_DESKTOP"

    spawn-at-startup "${pkgs.swaybg}/bin/swaybg" "-i" "${wallpaper}" "-m" "fill"

    spawn-at-startup "${pkgs.systemd}/bin/systemctl" "--user" "restart" "swayosd.service"


    // ─────────────────────────────────────────────────────────
    // Window rules
    // ─────────────────────────────────────────────────────────

    window-rule {
        match app-id="org.gnome.Loupe"
        open-floating true
    }

    window-rule {
        match app-id="org.gnome.Nautilus"
        open-floating true
    }

    window-rule {
        match app-id="org.gnome.Nautilus" title=".*Properties.*"
        open-floating true
    }

    window-rule {
        match app-id="org.gnome.Nautilus" title=".*(Progress|Conflict|Error|Warning).*"
        open-floating true
    }

    window-rule {
        match app-id="pavucontrol"
        open-floating true
    }

    window-rule {
        match app-id="xdg-desktop-portal-gtk"
        open-floating true

        default-column-width {
            fixed 900
        }

        default-window-height {
            fixed 600
        }
    }




    // ─────────────────────────────────────────────────────────
    // Cursor
    // ─────────────────────────────────────────────────────────

    cursor {
        xcursor-theme "Bibata-Modern-Ice"
        xcursor-size 20
    }


    // ─────────────────────────────────────────────────────────
    // Screenshots
    // ─────────────────────────────────────────────────────────

    screenshot-path "~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png"


    // ─────────────────────────────────────────────────────────
    // Hotkey overlay
    // ─────────────────────────────────────────────────────────

    hotkey-overlay {
        skip-at-startup
    }


    // ═══════════════════════════════════════════════════════════
    // KEYBINDINGS
    // ═══════════════════════════════════════════════════════════

    binds {

        // ─────────────────────────────────────────────────────
        // Applications
        // ─────────────────────────────────────────────────────

        ${mod}+Return {
            spawn "${terminal}";
        }

        ${mod}+Z {
            spawn "zeditor";
        }

        ${mod}+C {
            spawn "zeditor" "/home/anurag/Documents/nixos-config";
        }

        ${mod}+S {
            spawn "flatpak" "run" "com.spotify.Client";
        }

        ${mod}+B {
            spawn "flatpak" "run" "app.zen_browser.zen";
        }

        ${mod}+E {
            spawn "nautilus";
        }


        // ─────────────────────────────────────────────────────
        // Vicinae
        // ─────────────────────────────────────────────────────

        ${mod}+Space {
            spawn "vicinae" "toggle";
        }

        ${mod}+V {
            spawn "vicinae" "vicinae://launch/clipboard/history";
        }


        // ─────────────────────────────────────────────────────
        // Window management
        // ─────────────────────────────────────────────────────

        ${mod}+W {
            close-window;
        }

        ${mod}+F {
            fullscreen-window;
        }

        ${mod}+Shift+Space {
            toggle-window-floating;
        }


        // ─────────────────────────────────────────────────────
        // Lock
        // ─────────────────────────────────────────────────────

        ${mod}+L {
            spawn "${lock}";
        }


        // ─────────────────────────────────────────────────────
        // Suspend
        // ─────────────────────────────────────────────────────

        ${mod}+Shift+Z {
            spawn "${suspend}";
        }


        // ─────────────────────────────────────────────────────
        // Screenshots
        // ─────────────────────────────────────────────────────

        Print {
            spawn "${shotRegion}";
        }

        ${mod}+Shift+S {
            spawn "${shotFull}";
        }


        // ─────────────────────────────────────────────────────
        // Focus
        // ─────────────────────────────────────────────────────

        ${mod}+Left {
            focus-column-left;
        }

        ${mod}+Right {
            focus-column-right;
        }

        ${mod}+Up {
            focus-window-up;
        }

        ${mod}+Down {
            focus-window-down;
        }


        // Vim-style focus
        ${mod}+H {
            focus-column-left;
        }

        ${mod}+J {
            focus-window-down;
        }

        ${mod}+K {
            focus-window-up;
        }

        ${mod}+Semicolon {
            focus-column-right;
        }


        // ─────────────────────────────────────────────────────
        // Move windows
        // ─────────────────────────────────────────────────────

        ${mod}+Shift+Left {
            move-column-left;
        }

        ${mod}+Shift+Right {
            move-column-right;
        }

        ${mod}+Shift+Up {
            move-window-up;
        }

        ${mod}+Shift+Down {
            move-window-down;
        }


        // ─────────────────────────────────────────────────────
        // Workspaces
        // ─────────────────────────────────────────────────────

        ${mod}+1 {
            focus-workspace 1;
        }

        ${mod}+2 {
            focus-workspace 2;
        }

        ${mod}+3 {
            focus-workspace 3;
        }

        ${mod}+4 {
            focus-workspace 4;
        }

        ${mod}+5 {
            focus-workspace 5;
        }

        ${mod}+6 {
            focus-workspace 6;
        }

        ${mod}+7 {
            focus-workspace 7;
        }

        ${mod}+8 {
            focus-workspace 8;
        }

        ${mod}+9 {
            focus-workspace 9;
        }

        ${mod}+0 {
            focus-workspace 10;
        }


        // ─────────────────────────────────────────────────────
        // Move windows to workspaces
        // ─────────────────────────────────────────────────────

        ${mod}+Shift+1 {
            move-window-to-workspace 1;
        }

        ${mod}+Shift+2 {
            move-window-to-workspace 2;
        }

        ${mod}+Shift+3 {
            move-window-to-workspace 3;
        }

        ${mod}+Shift+4 {
            move-window-to-workspace 4;
        }

        ${mod}+Shift+5 {
            move-window-to-workspace 5;
        }

        ${mod}+Shift+6 {
            move-window-to-workspace 6;
        }

        ${mod}+Shift+7 {
            move-window-to-workspace 7;
        }

        ${mod}+Shift+8 {
            move-window-to-workspace 8;
        }

        ${mod}+Shift+9 {
            move-window-to-workspace 9;
        }

        ${mod}+Shift+0 {
            move-window-to-workspace 10;
        }


        // ─────────────────────────────────────────────────────
        // Workspace navigation
        // ─────────────────────────────────────────────────────

        ${mod}+Page_Down {
            focus-workspace-down;
        }

        ${mod}+Page_Up {
            focus-workspace-up;
        }

        ${mod}+WheelScrollDown cooldown-ms=150 {
            focus-workspace-down;
        }

        ${mod}+WheelScrollUp cooldown-ms=150 {
            focus-workspace-up;
        }


        // ─────────────────────────────────────────────────────
        // Column navigation
        // ─────────────────────────────────────────────────────

        ${mod}+WheelScrollRight {
            focus-column-right;
        }

        ${mod}+WheelScrollLeft {
            focus-column-left;
        }


        // ─────────────────────────────────────────────────────
        // Column sizing
        // ─────────────────────────────────────────────────────

        ${mod}+Minus {
            set-column-width "-10%";
        }

        ${mod}+Equal {
            set-column-width "+10%";
        }

        ${mod}+R {
            switch-preset-column-width;
        }


        // ─────────────────────────────────────────────────────
        // Column/window manipulation
        // ─────────────────────────────────────────────────────

        ${mod}+BracketLeft {
            consume-or-expel-window-left;
        }

        ${mod}+BracketRight {
            consume-or-expel-window-right;
        }

        ${mod}+Comma {
            consume-window-into-column;
        }

        ${mod}+Period {
            expel-window-from-column;
        }


        // ─────────────────────────────────────────────────────
        // Media
        // ─────────────────────────────────────────────────────

        XF86AudioPlay {
            spawn "playerctl" "play-pause";
        }

        XF86AudioNext {
            spawn "playerctl" "next";
        }

        XF86AudioPrev {
            spawn "playerctl" "previous";
        }


        // ─────────────────────────────────────────────────────
        // Volume
        // ─────────────────────────────────────────────────────

        XF86AudioRaiseVolume {
            spawn "${swayosdBin}" "--output-volume" "raise";
        }

        XF86AudioLowerVolume {
            spawn "${swayosdBin}" "--output-volume" "lower";
        }

        XF86AudioMute {
            spawn "${swayosdBin}" "--output-volume" "mute-toggle";
        }

        XF86AudioMicMute {
            spawn "${swayosdBin}" "--input-volume" "mute-toggle";
        }


        // ─────────────────────────────────────────────────────
        // Brightness
        // ─────────────────────────────────────────────────────

        XF86MonBrightnessUp {
            spawn "${swayosdBin}" "--brightness" "raise";
        }

        XF86MonBrightnessDown {
            spawn "${swayosdBin}" "--brightness" "lower";
        }
    }
  '';

  # ═══════════════════════════════════════════════════════════════
  # MAKO
  # ═══════════════════════════════════════════════════════════════

  services.mako = {
    enable = true;

    settings = {
      font = "JetBrains Mono 10";
      background-color = surface;
      text-color = text;
      border-color = overlay;
      border-size = 1;
      border-radius = 0;
      padding = "6,12";
      margin = "6";
      width = 280;
      height = 64;
      default-timeout = 3000;
      anchor = "top-right";
    };
  };

  # ═══════════════════════════════════════════════════════════════
  # SWAYIDLE
  # ═══════════════════════════════════════════════════════════════

  services.swayidle = {
    enable = true;

    events = {
      before-sleep = lock;
      lock = lock;
      unlock = "";
    };

    timeouts = [
      {
        # 5 minutes -> lock
        timeout = 300;
        command = lock;
      }

      {
        # 10 minutes -> suspend
        timeout = 600;
        command = suspend;
      }
    ];
  };

  # ═══════════════════════════════════════════════════════════════
  # SWAYOSD
  # ═══════════════════════════════════════════════════════════════

  services.swayosd = {
    enable = true;
    stylePath = swayosdStyle;
  };

  xdg.configFile."swayosd/config.toml".text = ''
    [server]
    show_percentage = true
    max_volume = 100
  '';

  # ═══════════════════════════════════════════════════════════════
  # SSH AGENT
  # ═══════════════════════════════════════════════════════════════

  services.ssh-agent.enable = true;

  programs.ssh = {
    enable = true;

    settings."*" = {
      AddKeysToAgent = "yes";
    };
  };

  # ═══════════════════════════════════════════════════════════════
  # AUTOSTART VICINAE
  # ═══════════════════════════════════════════════════════════════

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

  # ═══════════════════════════════════════════════════════════════
  # GTK
  # ═══════════════════════════════════════════════════════════════

  gtk = {
    enable = true;

    font = {
      name = "JetBrains Mono";
      size = 11;
    };

    iconTheme = {
      name = "Adwaita";
      package = pkgs.adwaita-icon-theme;
    };

    cursorTheme = {
      name = "Bibata-Modern-Ice";
      size = 20;
      package = pkgs.bibata-cursors;
    };

    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
      gtk-xft-antialias = 1;
      gtk-xft-hinting = 1;
      gtk-xft-hintstyle = "hintfull";
      gtk-xft-rgba = "rgb";
    };

    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
      gtk-xft-antialias = 1;
      gtk-xft-hinting = 1;
      gtk-xft-hintstyle = "hintfull";
      gtk-xft-rgba = "rgb";
    };
  };
}
