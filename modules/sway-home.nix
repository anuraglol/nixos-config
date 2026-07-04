{ pkgs, lib, ... }:

let
  mod = "Mod4";
  terminal = "kitty";
  lock = "${pkgs.hyprlock}/bin/hyprlock";
  # Fork to background so swayidle -w doesn't block forever on the lock screen.
  lockBg = "pidof hyprlock || ${lock} &";

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

  icon =
    let
      imod = a: b: a - (a / b) * b;
      hexChars = lib.stringToCharacters "0123456789abcdef";
      nibble = n: builtins.elemAt hexChars (imod n 16);
      toHex4 = n: "${nibble (n / 4096)}${nibble (n / 256)}${nibble (n / 16)}${nibble n}";
      hexVal = {
        "0" = 0;
        "1" = 1;
        "2" = 2;
        "3" = 3;
        "4" = 4;
        "5" = 5;
        "6" = 6;
        "7" = 7;
        "8" = 8;
        "9" = 9;
        "a" = 10;
        "b" = 11;
        "c" = 12;
        "d" = 13;
        "e" = 14;
        "f" = 15;
      };
      hexToInt =
        s: lib.foldl' (acc: c: acc * 16 + hexVal.${c}) 0 (lib.stringToCharacters (lib.toLower s));
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

  shotFull = pkgs.writeShellScript "shot-full" ''
    ${pkgs.grim}/bin/grim - | ${pkgs.wl-clipboard}/bin/wl-copy \
      && ${pkgs.libnotify}/bin/notify-send "Screenshot" "Full screen copied to clipboard"
  '';

  shotRegion = pkgs.writeShellScript "shot-region" ''
    geom=$(${pkgs.slurp}/bin/slurp) || exit 0
    ${pkgs.grim}/bin/grim -g "$geom" - | ${pkgs.wl-clipboard}/bin/wl-copy \
      && ${pkgs.libnotify}/bin/notify-send "Screenshot" "Region copied to clipboard"
  '';

  wifiMenu = "vicinae vicinae://launch/@dagimg-dot/store.vicinae.wifi-commander/scan-wifi";
  btMenu = "vicinae vicinae://launch/@Gelei/store.vicinae.bluetooth/devices";
  powerMenu = "vicinae vicinae://launch/@botkooper/store.vicinae.power-profile/power-profile";

  swayosd-client = "${pkgs.swayosd}/bin/swayosd-client";

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

    progressbar trough {
      background-color: ${highlightMed};
    }
    progress {
      background-color: ${iris};
    }
  '';

  nightToggle = pkgs.writeShellScript "nightlight-toggle" ''
    if ${pkgs.procps}/bin/pgrep -x wlsunset >/dev/null; then
      ${pkgs.procps}/bin/pkill -x wlsunset
    else
      ${pkgs.wlsunset}/bin/wlsunset -t 3499 -T 3500 >/dev/null 2>&1 &
    fi
    ${pkgs.procps}/bin/pkill -RTMIN+8 waybar || true
  '';

  nightStatus = pkgs.writeShellScript "nightlight-status" ''
    if ${pkgs.procps}/bin/pgrep -x wlsunset >/dev/null; then
      printf '{"text":"%s","class":"active","tooltip":"Night light on"}\n' '${icon "f186"}'
    else
      printf '{"text":"%s","tooltip":"Night light off"}\n' '${icon "f185"}'
    fi
  '';

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
    package = null;
    checkConfig = false;

    config = {
      modifier = mod;
      terminal = terminal;
      menu = "vicinae toggle";

      fonts = {
        names = [ "JetBrains Mono" ];
        size = 11.5;
      };

      window = {
        border = 1;
        titlebar = true;
      };

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

      bars = [ ];

      input = {
        "type:touchpad" = {
          tap = "enabled";
          natural_scroll = "enabled";
          dwt = "enabled";
          pointer_accel = "-0.253219";
        };
        "type:pointer" = {
          accel_profile = "flat";
          pointer_accel = "0.107296";
        };
      };

      startup = [
        { command = "${pkgs.mako}/bin/mako"; }
        { command = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"; }
        {
          command = "${pkgs.systemd}/bin/systemctl --user import-environment WAYLAND_DISPLAY SWAYSOCK XDG_CURRENT_DESKTOP && ${pkgs.systemd}/bin/systemctl --user restart waybar.service swayidle.service swayosd.service";
        }
      ];

      seat."*".xcursor_theme = "Bibata-Modern-Ice 20";

      output."*" = {
        bg = "~/.config/background fill";
        scale = "1.5";
      };

      keybindings = lib.mkOptionDefault (
        moveFollow
        // {
          "${mod}+w" = "kill";
          "${mod}+f" = "fullscreen toggle";
          "${mod}+l" = "exec ${lock}";

          "${mod}+Return" = "exec ${terminal}";
          "${mod}+z" = "exec zeditor";
          "${mod}+c" = "exec zeditor /home/anurag/Documents/nixos-config";
          "${mod}+s" = "exec flatpak run com.spotify.Client";
          "${mod}+b" = "exec flatpak run app.zen_browser.zen";
          "${mod}+e" = "exec nautilus";

          "${mod}+space" = "exec vicinae toggle";
          "${mod}+v" = "exec vicinae vicinae://launch/clipboard/history";

          "Print" = "exec ${shotRegion}";
          "${mod}+Shift+s" = "exec ${shotFull}";

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
      smart_borders on

      bindgesture swipe:3:right workspace prev
      bindgesture swipe:3:left workspace next

      workspace number 1
    '';
  };

  services.swayidle = {
    enable = true;
    events = [
      {
        event = "before-sleep";
        command = lockBg;
      }
      {
        event = "after-resume";
        command = "swaymsg 'output * power on'";
      }
    ];
    timeouts = [
      {
        timeout = 300;
        command = lockBg;
      }
      {
        timeout = 300;
        command = "swaymsg 'output * power off'";
        resumeCommand = "swaymsg 'output * power on'";
      }
      {
        timeout = 600;
        command = "systemctl suspend";
      }
    ];
  };

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
          focused = icon "f14fb";
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

      clock = {
        format = "<span size='small'>{:%a %H:%M}</span>";
        format-alt = "<span size='small'>{:%d %B  W%V %Y}</span>";
        tooltip = false;
      };

      idle_inhibitor = {
        format = "{icon}";
        format-icons = {
          activated = icon "f06e";
          deactivated = icon "f070";
        };
        tooltip = false;
      };

      "custom/nightlight" = {
        format = "{}";
        return-type = "json";
        exec = "${nightStatus}";
        on-click = "${nightToggle}";
        interval = 5;
        signal = 8;
      };

      cpu = {
        format = "${icon "f035b"} <span size='small'>{usage}%</span>";
        interval = 5;
      };
      memory = {
        format = "${icon "f1c0"} <span size='small'>{percentage}%</span>";
        interval = 5;
        tooltip-format = "RAM: {used:0.1f} GiB / {total:0.1f} GiB\nSwap: {swapUsed:0.1f} GiB / {swapTotal:0.1f} GiB";
      };
      bluetooth = {
        format = icon "f00af";
        format-off = icon "f00b2";
        format-disabled = icon "f00b2";
        format-connected = "${icon "f00b1"} {num_connections}";
        on-click = "${btMenu}";
        tooltip-format = "{controller_alias}";
      };
      network = {
        format-wifi = "{icon} <span size='small'>{signalStrength}%</span>";
        format-ethernet = icon "f0002";
        format-disconnected = icon "f092e";
        format-icons = map icon [
          "f092f"
          "f091f"
          "f0922"
          "f0925"
          "f0928"
        ];
        tooltip-format = "{essid} ({ipaddr})";
        tooltip-format-disconnected = "Disconnected";
        on-click = "${wifiMenu}";
        interval = 5;
      };
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
        on-click = "${powerMenu}";
        interval = 2.5;
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
        font-family: "JetBrainsMono Nerd Font Mono", "JetBrains Mono", monospace;
        font-size: 16px;
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

      #workspaces button {
        all: initial;
        font-family: "JetBrainsMono Nerd Font Mono", "JetBrains Mono", monospace;
        font-size: 16px;
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

  services.swayosd = {
    enable = true;
    stylePath = "${swayosdStyle}";
  };
  xdg.configFile."swayosd/config.toml".text = ''
    [server]
    show_percentage = true
    max_volume = 100
  '';

  programs.hyprlock = {
    enable = true;
    settings = {
      general = {
        hide_cursor = true;
        ignore_empty_input = true;
      };

      animations.enabled = false;

      auth."fingerprint:enabled" = false;

      background = [
        {
          monitor = "";
          color = "rgba(25, 23, 36, 1.0)";
        }
      ];

      input-field = [
        {
          monitor = "";
          size = "460, 65";
          position = "0, 0";
          halign = "center";
          valign = "center";

          inner_color = "rgba(31, 29, 46, 1.0)";
          outer_color = "rgba(64, 61, 82, 1.0)";
          outline_thickness = 4;
          rounding = 0;

          font_family = "JetBrainsMono Nerd Font";
          font_color = "rgba(224, 222, 244, 1.0)";
          placeholder_text = "Enter Password";

          dots_center = true;
          check_color = "rgba(156, 207, 216, 1.0)";
          fail_color = "rgba(235, 111, 146, 1.0)";
          fail_text = "<i>$FAIL ($ATTEMPTS)</i>";
          capslock_color = "rgba(246, 193, 119, 1.0)";

          shadow_passes = 0;
          fade_on_empty = false;
        }
      ];

      # Quiet info row below the input: time on the left, battery on the right
      label = [
        {
          monitor = "";
          text = "cmd[update:1000] date +%H:%M";
          font_family = "JetBrainsMono Nerd Font";
          font_size = 13;
          color = "rgba(110, 106, 134, 1.0)";
          position = "-40, -75";
          halign = "center";
          valign = "center";
        }
        {
          monitor = "";
          text = ''cmd[update:30000] echo "󰁹 $(cat /sys/class/power_supply/BAT0/capacity)%"'';
          font_family = "JetBrainsMono Nerd Font";
          font_size = 13;
          color = "rgba(110, 106, 134, 1.0)";
          position = "40, -75";
          halign = "center";
          valign = "center";
        }
      ];
    };
  };

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
