{ pkgs, lib, ... }:

# Minimal Sway config (home-manager). Mostly stock defaults; the main
# customisation is porting your GNOME super-key shortcuts (see modules/dconf.nix)
# so muscle memory carries over. Defaults still in effect:
#   Super+h/j/k/l (+Shift to move) navigate, Super+1..9 workspaces,
#   Super+r resize mode, Super+Shift+e exit, Super+Shift+c reload,
#   Super+drag to move/resize floating windows.
let
  mod = "Mod4"; # Super / Windows key
  terminal = "kitty";
  # rose-pine hyprlock (config in programs.hyprlock below) — clock + date + input
  # field. hyprlock draws via ext-session-lock-v1, which sway supports, so it
  # runs fine outside Hyprland. swayidle spawns it async, so no fork flag needed.
  lock = "${pkgs.hyprlock}/bin/hyprlock";

  # Rosé Pine palette
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

  # Build a Nerd Font glyph from its hex codepoint. Embedding the raw glyph
  # bytes in this file is unreliable (private-use chars get stripped), so we
  # decode them from JSON \u escapes instead. Handles both BMP (one \u) and
  # astral codepoints (a UTF-16 surrogate pair) — the latter covers the
  # Material-Design Nerd Font icons at U+F0000+ that omarchy uses.
  icon =
    let
      imod = a: b: a - (a / b) * b;
      hexChars = lib.stringToCharacters "0123456789abcdef";
      nibble = n: builtins.elemAt hexChars (imod n 16);
      toHex4 = n: "${nibble (n / 4096)}${nibble (n / 256)}${nibble (n / 16)}${nibble n}";
      hexVal = {
        "0" = 0; "1" = 1; "2" = 2; "3" = 3; "4" = 4; "5" = 5; "6" = 6; "7" = 7;
        "8" = 8; "9" = 9; "a" = 10; "b" = 11; "c" = 12; "d" = 13; "e" = 14; "f" = 15;
      };
      hexToInt = s: lib.foldl' (acc: c: acc * 16 + hexVal.${c}) 0 (
        lib.stringToCharacters (lib.toLower s)
      );
    in
    cp:
    let
      n = hexToInt cp;
    in
    if n < 65536 then
      builtins.fromJSON ''"\u${toHex4 n}"''
    else
      let
        c = n - 65536;
        hi = 55296 + (c / 1024);
        lo = 56320 + (imod c 1024);
      in
      builtins.fromJSON ''"\u${toHex4 hi}\u${toHex4 lo}"'';

  # screenshots -> clipboard, with a confirmation notification.
  shotFull = pkgs.writeShellScript "shot-full" ''
    ${pkgs.grim}/bin/grim - | ${pkgs.wl-clipboard}/bin/wl-copy \
      && ${pkgs.libnotify}/bin/notify-send "Screenshot" "Full screen copied to clipboard"
  '';

  shotRegion = pkgs.writeShellScript "shot-region" ''
    geom=$(${pkgs.slurp}/bin/slurp) || exit 0
    ${pkgs.grim}/bin/grim -g "$geom" - | ${pkgs.wl-clipboard}/bin/wl-copy \
      && ${pkgs.libnotify}/bin/notify-send "Screenshot" "Region copied to clipboard"
  '';

  # wifi / bluetooth handled by vicinae extensions (clicked from waybar).
  # launch/ deeplinks jump straight to the specific command.
  wifiMenu = "vicinae vicinae://launch/@dagimg-dot/store.vicinae.wifi-commander/scan-wifi";
  btMenu = "vicinae vicinae://launch/@Gelei/store.vicinae.bluetooth/devices";

  # volume/brightness OSD via swayosd (server enabled below). The client tells
  # the running server to apply the change and show its popup.
  swayosd-client = "${pkgs.swayosd}/bin/swayosd-client";

  # swayosd stylesheet — omarchy's layout, rose-pine colours, square corners.
  swayosdStyle = pkgs.writeText "swayosd-style.css" ''
    window {
      border-radius: 0;
      opacity: 0.97;
      border: 2px solid ${highlightMed};
      background-color: ${surface};
    }

    label {
      font-family: 'JetBrainsMono Nerd Font';
      font-size: 11pt;
      color: ${text};
    }

    image {
      color: ${text};
    }

    progressbar {
      border-radius: 0;
    }

    /* unfilled track + filled portion */
    progressbar trough {
      background-color: ${highlightMed};
    }
    progress {
      background-color: ${iris};
    }
  '';

  # night light = manual wlsunset toggle (no geo schedule — on when you want,
  # off when you want). Holding a *constant* warm temp is the trick: with no
  # lat/long wlsunset stays in "always day" mode and parks the screen at the
  # high temp, so high=3500 just above low=3499 gives a steady 3500 K. (With
  # geo it would only warm after sunset, which is why it seemed broken.)
  # Pokes waybar (RTMIN+8) to refresh the icon.
  nightToggle = pkgs.writeShellScript "nightlight-toggle" ''
    if ${pkgs.procps}/bin/pgrep -x wlsunset >/dev/null; then
      ${pkgs.procps}/bin/pkill -x wlsunset
    else
      ${pkgs.wlsunset}/bin/wlsunset -t 3499 -T 3500 >/dev/null 2>&1 &
    fi
    ${pkgs.procps}/bin/pkill -RTMIN+8 waybar || true
  '';

  # JSON output so the active (warm) state can be coloured via the .active CSS
  # class. text comes from the icon helper (avoids raw glyph bytes in-file).
  nightStatus = pkgs.writeShellScript "nightlight-status" ''
    if ${pkgs.procps}/bin/pgrep -x wlsunset >/dev/null; then
      printf '{"text":"%s","class":"active","tooltip":"Night light on"}\n' '${icon "f186"}'
    else
      printf '{"text":"%s","tooltip":"Night light off"}\n' '${icon "f185"}'
    fi
  '';

  # move a window to workspace N *and follow it there* (GNOME behaviour)
  moveFollow = builtins.listToAttrs (
    map
      (n: {
        name = "${mod}+Shift+${toString n}";
        value = "move container to workspace number ${toString n}; workspace number ${toString n}";
      })
      [
        1
        2
        3
        4
        5
        6
        7
        8
        9
        0
      ]
  );
in
{
  wayland.windowManager.sway = {
    enable = true;
    package = null; # use the system sway from programs.sway (modules/sway.nix)
    checkConfig = false; # config check can't run a wrapped/null package at build

    config = {
      modifier = mod;
      terminal = terminal;
      menu = "vicinae toggle";

      fonts = {
        names = [ "JetBrains Mono" ];
        size = 11.5;
      };

      # Title bar always on; side borders only appear when a workspace has more
      # than one window (smart_borders, set in extraConfig).
      window = {
        border = 2;
        titlebar = true;
      };

      # Monochrome rose-pine window colours (no default blue).
      # order: border background text indicator childBorder
      colors = {
        focused = {
          border = overlay;
          background = surface;
          text = text;
          indicator = subtle;
          childBorder = muted;
        };
        focusedInactive = {
          border = surface;
          background = surface;
          text = subtle;
          indicator = overlay;
          childBorder = overlay;
        };
        unfocused = {
          border = base;
          background = base;
          text = muted;
          indicator = overlay;
          childBorder = surface;
        };
        urgent = {
          border = base;
          background = base;
          text = love;
          indicator = love;
          childBorder = love;
        };
      };

      # Use waybar instead of the built-in swaybar.
      bars = [ ];

      input = {
        "type:touchpad" = {
          tap = "enabled";
          natural_scroll = "enabled"; # natural scrolling on (like GNOME)
          dwt = "enabled"; # disable-while-typing
          pointer_accel = "-0.253219"; # matches GNOME touchpad speed
        };
        "type:pointer" = {
          accel_profile = "flat"; # matches GNOME flat mouse profile
          pointer_accel = "0.107296"; # matches GNOME mouse speed
        };
      };

      # start the notification daemon with the session
      startup = [ { command = "${pkgs.mako}/bin/mako"; } ];

      seat."*".xcursor_theme = "Bibata-Modern-Ice 20";

      output."*" = {
        bg = "~/.config/background fill";
        scale = "1.5";
      };

      # Ported super-key shortcuts. mkOptionDefault keeps all of sway's stock
      # bindings and just layers these on top.
      keybindings = lib.mkOptionDefault (
        moveFollow
        // {
          # window / session
          "${mod}+w" = "kill"; # GNOME: close window
          "${mod}+f" = "fullscreen toggle"; # GNOME: toggle fullscreen
          "${mod}+l" = "exec ${lock}"; # lock screen

          # app launchers (GNOME custom keybindings)
          "${mod}+Return" = "exec ${terminal}";
          "${mod}+z" = "exec zeditor";
          "${mod}+c" = "exec zeditor /home/anurag/Documents/nixos-config";
          "${mod}+s" = "exec flatpak run com.spotify.Client";
          "${mod}+b" = "flatpak run app.zen_browser.zen"; # GNOME: www
          "${mod}+e" = "exec nautilus"; # GNOME: home

          # vicinae
          "${mod}+space" = "exec vicinae toggle";
          "${mod}+v" = "exec vicinae vicinae://launch/clipboard/history";

          # screenshots (to clipboard, with notification)
          "Print" = "exec ${shotFull}";
          "${mod}+Shift+s" = "exec ${shotRegion}";

          # media / laptop keys
          "XF86AudioRaiseVolume" = "exec ${swayosd-client} --output-volume raise";
          "XF86AudioLowerVolume" = "exec ${swayosd-client} --output-volume lower";
          "XF86AudioMute" = "exec ${swayosd-client} --output-volume mute-toggle";
          "XF86AudioMicMute" = "exec ${swayosd-client} --input-volume mute-toggle";
          "XF86MonBrightnessUp" = "exec ${swayosd-client} --brightness raise";
          "XF86MonBrightnessDown" = "exec ${swayosd-client} --brightness lower";
          "XF86AudioPlay" = "exec playerctl play-pause";
          "XF86AudioNext" = "exec playerctl next";
          "XF86AudioPrev" = "exec playerctl previous";
        }
      );
    };

    extraConfig = ''
      # side borders only when a workspace has >1 window
      smart_borders on

      # three-finger touchpad swipe to switch workspaces
      bindgesture swipe:3:right workspace prev
      bindgesture swipe:3:left workspace next
    '';
  };

  # Auto-lock + lock-before-suspend. Manual lock is Super+L.
  services.swayidle = {
    enable = true;
    events = [
      {
        event = "before-sleep";
        command = lock;
      }
    ];
    timeouts = [
      {
        timeout = 300; # lock after 5 min idle
        command = lock;
      }
      {
        timeout = 600; # screen off after 10 min idle
        command = "swaymsg 'output * power off'";
        resumeCommand = "swaymsg 'output * power on'";
      }
    ];
  };

  # Waybar: monochrome rose-pine, JetBrains Mono Nerd Font, common system info.
  programs.waybar = {
    enable = true;
    systemd.enable = true;
    settings.mainBar = {
      layer = "top";
      position = "top";
      height = 30;
      spacing = 0;
      modules-left = [
        "sway/workspaces"
        "sway/mode"
      ];
      modules-center = [ "clock" ];
      modules-right = [
        "tray"
        "idle_inhibitor"
        "custom/nightlight"
        "cpu"
        "memory"
        "bluetooth"
        "network"
        "pulseaudio"
        "battery"
      ];

      # Workspaces — omarchy dot style: the active workspace shows a filled
      # dot, the others show their number; 1-5 are always present.
      "sway/workspaces" = {
        format = "{icon}";
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
          focused = icon "f14fb"; # filled dot on the active workspace
          urgent = icon "f14fb";
        };
        persistent-workspaces = {
          "1" = [ ];
          "2" = [ ];
          "3" = [ ];
          "4" = [ ];
          "5" = [ ];
        };
      };

      # day + time; click toggles to the long date (omarchy behaviour).
      # text is sized down via pango <span> so it stays smaller than the glyphs
      # (glyph + text share the module font-size, so CSS can't split them).
      clock = {
        format = "<span size='small'>{:%a %H:%M}</span>";
        format-alt = "<span size='small'>{:%d %B  W%V %Y}</span>";
        tooltip = false;
      };

      # caffeine: click to inhibit idle (no lock/blank while activated)
      idle_inhibitor = {
        format = "{icon}";
        format-icons = {
          activated = icon "f06e"; # eye (staying awake)
          deactivated = icon "f070"; # eye-slash
        };
        tooltip = false;
      };

      # night light: click toggles a constant-warm wlsunset (see nightToggle).
      # return-type json so the warm state gets the .active CSS colour.
      "custom/nightlight" = {
        format = "{}";
        return-type = "json";
        exec = "${nightStatus}";
        on-click = "${nightToggle}";
        interval = 5;
        signal = 8;
      };

      cpu = {
        format = "${icon "f035b"} <span size='small'>{usage}%</span>"; # chip
        interval = 5;
      };
      memory = {
        format = "${icon "f1c0"} <span size='small'>{percentage}%</span>"; # memory bank
        interval = 5;
      };
      # bluetooth (omarchy md glyphs); click -> vicinae bluetooth picker
      bluetooth = {
        format = icon "f00af"; # bluetooth (on, nothing connected)
        format-off = icon "f00b2"; # bluetooth-off
        format-disabled = icon "f00b2";
        format-connected = "${icon "f00b1"} {num_connections}"; # bluetooth-connect
        on-click = "${btMenu}";
        tooltip-format = "{controller_alias}";
      };
      # network (omarchy md signal arcs); click -> vicinae wifi picker
      network = {
        format-wifi = "{icon} <span size='small'>{signalStrength}%</span>";
        format-ethernet = icon "f0002"; # check-network (wired)
        format-disconnected = icon "f092e"; # wifi-off
        format-icons = map icon [
          "f092f" # wifi-strength-off-outline (weakest)
          "f091f" # wifi-strength-1
          "f0922" # wifi-strength-2
          "f0925" # wifi-strength-3
          "f0928" # wifi-strength-4 (strongest)
        ];
        tooltip-format = "{essid} ({ipaddr})";
        tooltip-format-disconnected = "Disconnected";
        on-click = "${wifiMenu}";
        interval = 5;
      };
      # battery (omarchy md ramps); separate charging glyphs
      battery = {
        format = "{icon} <span size='small'>{capacity}%</span>";
        format-charging = "{icon} <span size='small'>{capacity}%</span>";
        format-full = "{icon} <span size='small'>{capacity}%</span>";
        format-icons = {
          default = map icon [
            "f007a"
            "f007b"
            "f007c"
            "f007d"
            "f007e"
            "f007f"
            "f0080"
            "f0081"
            "f0082"
            "f0079"
          ];
          charging = map icon [
            "f089c"
            "f0086"
            "f0087"
            "f0088"
            "f089d"
            "f0089"
            "f089e"
            "f008a"
            "f008b"
            "f0085"
          ];
        };
        states = {
          warning = 20;
          critical = 10;
        };
        interval = 5;
      };
      pulseaudio = {
        format = "{icon} <span size='small'>{volume}%</span>";
        format-muted = "${icon "f026"} <span size='small'>muted</span>";
        format-icons.default = map icon [
          "f026"
          "f027"
          "f028"
        ];
        on-click = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
        scroll-step = 5;
      };
    };

    style = ''
      * {
        /* the *Mono* nerd variant forces every icon to one cell width, so the
           icon-to-text gap is identical across all modules */
        font-family: "JetBrainsMono Nerd Font Mono", "JetBrains Mono", monospace;
        font-size: 15px;
        font-weight: 500;
        border: none;
        border-radius: 0;
        min-height: 0;
      }
      window#waybar {
        background: ${base};
        color: ${text};
      }
      .modules-left {
        margin-left: 6px;
      }
      .modules-right {
        margin-right: 6px;
      }

      /* workspaces: flat text-only buttons (omarchy). all:initial strips GTK's
         default button chrome, so re-apply font + colour here. */
      #workspaces button {
        all: initial;
        font-family: "JetBrainsMono Nerd Font Mono", "JetBrains Mono", monospace;
        font-size: 15px;
        color: ${muted};
        padding: 0 7px;
        margin: 0 1px;
        min-width: 9px;
      }
      #workspaces button.focused,
      #workspaces button.visible {
        color: ${iris};
      }
      #workspaces button.urgent {
        color: ${love};
      }
      #workspaces button.empty {
        opacity: 0.45;
      }

      #clock,
      #cpu, #memory, #network, #bluetooth, #pulseaudio, #battery,
      #tray, #mode, #idle_inhibitor, #custom-nightlight {
        padding: 0 8px;
        color: ${text};
      }

      /* state colours */
      #idle_inhibitor.deactivated   { color: ${muted}; }
      #idle_inhibitor.activated     { color: ${gold}; }
      #custom-nightlight.active     { color: ${gold}; }
      #pulseaudio.muted             { color: ${muted}; }
      #network.disconnected         { color: ${muted}; }
      #bluetooth.off,
      #bluetooth.disabled           { color: ${muted}; }
      #battery.charging             { color: ${foam}; }
      #battery.warning:not(.charging)  { color: ${gold}; }
      #battery.critical:not(.charging) { color: ${love}; }
    '';
  };

  # Notifications: mako, compact (omarchy-ish) rose-pine. Short height, thin
  # border, square corners.
  services.mako = {
    enable = true;
    settings = {
      font = "JetBrains Mono 10";
      background-color = surface;
      text-color = text;
      border-color = overlay;
      border-size = 1;
      border-radius = 0; # square corners (matches the OSD sketch)
      padding = "6,12";
      margin = "6";
      width = 280;
      height = 64;
      default-timeout = 3000;
      anchor = "top-right";
    };
  };

  # Volume / brightness OSD: swayosd (server runs as a user service; keybindings
  # call swayosd-client). config.toml is auto-discovered by the server.
  services.swayosd = {
    enable = true;
    stylePath = "${swayosdStyle}";
  };
  xdg.configFile."swayosd/config.toml".text = ''
    [server]
    show_percentage = true
    max_volume = 100
  '';

  # Lock screen: rose-pine hyprlock, omarchy-style — a single centred square
  # input field, thick outline, no animations, attempt-count fail text. Flat
  # base colour (no wallpaper/blur, unlike omarchy), no clock/date.
  # Needs security.pam.services.hyprlock, set system-side in modules/sway.nix.
  programs.hyprlock = {
    enable = true;
    settings = {
      general = {
        hide_cursor = true;
        ignore_empty_input = true; # Enter on an empty field does nothing
      };

      animations.enabled = false;

      auth."fingerprint:enabled" = false;

      # Solid Rosé Pine base — no wallpaper.
      background = [
        {
          monitor = "";
          color = "rgba(25, 23, 36, 1.0)"; # base #191724
        }
      ];

      input-field = [
        {
          monitor = "";
          size = "400, 55";
          position = "0, 0";
          halign = "center";
          valign = "center";

          inner_color = "rgba(31, 29, 46, 1.0)"; # surface
          outer_color = "rgba(64, 61, 82, 1.0)"; # highlight med
          outline_thickness = 4;
          rounding = 0;

          font_family = "JetBrainsMono Nerd Font";
          font_color = "rgba(224, 222, 244, 1.0)"; # text
          placeholder_text = "Enter Password";

          dots_center = true;
          check_color = "rgba(156, 207, 216, 1.0)"; # foam (verifying)
          fail_color = "rgba(235, 111, 146, 1.0)"; # love (wrong)
          fail_text = "<i>$FAIL ($ATTEMPTS)</i>";
          capslock_color = "rgba(246, 193, 119, 1.0)"; # gold

          shadow_passes = 0;
          fade_on_empty = false;
        }
      ];
    };
  };

  # Fix GTK font rendering under sway (no gnome-settings-daemon here to apply
  # hinting/antialiasing). Also sets the dark preference + cursor for GTK apps.
  gtk = {
    enable = true;
    font = {
      name = "JetBrains Mono";
      size = 11;
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

  home.packages = with pkgs; [
    grim
    slurp
    brightnessctl
    playerctl
  ];
}
