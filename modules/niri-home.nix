{ pkgs, lib, config, ... }:

let
  mod = "Mod";
  terminal = "kitty";

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

  # Unicode codepoint -> string helper (same as the sway/waybar modules).
  icon =
    let
      imod = a: b: a - (a / b) * b;
      hexChars = lib.stringToCharacters "0123456789abcdef";
      nibble = n: builtins.elemAt hexChars (imod n 16);
      toHex4 = n: "${nibble (n / 4096)}${nibble (n / 256)}${nibble (n / 16)}${nibble n}";
      hexVal = {
        "0" = 0; "1" = 1; "2" = 2; "3" = 3; "4" = 4;
        "5" = 5; "6" = 6; "7" = 7; "8" = 8; "9" = 9;
        "a" = 10; "b" = 11; "c" = 12; "d" = 13; "e" = 14; "f" = 15;
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

  lock = "${pkgs.swaylock}/bin/swaylock --color 191724ff";
  lockBg = "${pkgs.procps}/bin/pidof swaylock >/dev/null 2>&1 || ${lock} &";

  niri = "${pkgs.niri}/bin/niri";
  systemctl = "${pkgs.systemd}/bin/systemctl";
  suspendCmd = "${niri} msg action power-on-monitors && ${systemctl} suspend";

  moveToWorkspace = ws: pkgs.writeShellScript "niri-move-ws-${ws}" ''
    ${niri} msg action move-column-to-workspace ${ws}
    ${niri} msg action focus-workspace ${ws}
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

  waybarNiriConfig = builtins.toJSON {
    layer = "top";
    position = "top";
    height = 28;
    spacing = 0;
    modules-left = [ "niri/workspaces" "niri/window" ];
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

    "niri/workspaces" = {
      format = "{name}";
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
      format = "{:%H:%M}";
      format-alt = "{:%a %d %b %Y}";
      tooltip = false;
    };

    idle_inhibitor = {
      format = "{icon}";
      format-icons = {
        activated = "caff";
        deactivated = "caff";
      };
      tooltip = false;
    };

    "custom/nightlight" = {
      format = "NL";
      return-type = "json";
      exec = "${nightStatus}";
      on-click = "${nightToggle}";
      interval = 5;
      signal = 8;
    };

    cpu = {
      format = "CPU {usage}%";
      interval = 5;
    };

    memory = {
      format = "RAM {percentage}%";
      interval = 5;
      tooltip-format = "RAM: {used:0.1f} GiB / {total:0.1f} GiB\nSwap: {swapUsed:0.1f} GiB / {swapTotal:0.1f} GiB";
    };

    bluetooth = {
      format = "BT on";
      format-off = "BT off";
      format-disabled = "BT disabled";
      format-connected = "BT {num_connections}";
      on-click = "${btMenu}";
      tooltip-format = "{controller_alias}";
    };

    network = {
      format-wifi = "NET {signalStrength}%";
      format-ethernet = "ETH up";
      format-disconnected = "NET off";
      tooltip-format = "{essid} ({ipaddr})";
      tooltip-format-disconnected = "Disconnected";
      on-click = "${wifiMenu}";
      interval = 5;
    };

    battery = {
      format = "BAT {capacity}%";
      format-charging = "BAT {capacity}%+";
      format-full = "BAT 100%";
      states = {
        warning = 20;
        critical = 10;
      };
      on-click = "${powerMenu}";
      interval = 2.5;
    };

    pulseaudio = {
      format = "VOL {volume}%";
      format-muted = "VOL muted";
      on-click = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
      scroll-step = 5;
    };
  };

  waybarNiriStyle = ''
    * {
      font-family: "JetBrainsMono Nerd Font Mono", "JetBrains Mono", monospace;
      font-size: 14px;
      font-weight: 500;
      border: none;
      border-radius: 0;
      min-height: 0;
    }
    window#waybar {
      background: ${base};
      color: ${text};
      min-height: 28px;
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
      font-size: 14px;
      font-weight: 500;
      color: ${muted};
      padding: 0 6px;
      margin: 0 1px;
      min-width: 9px;
    }

    #workspaces button.active {
      color: ${iris};
      background: ${surface};
      border-radius: 4px;
      padding: 0 8px;
      margin: 0px 0px;
      min-height: 24px;
    }

    #workspaces button.visible {
      color: ${iris};
    }

    #workspaces button.urgent {
      color: ${love};
      background: ${surface};
      border-radius: 4px;
      padding: 0 8px;
      margin: 3px 2px;
    }

    #workspaces button.empty {
      opacity: 0.45;
    }

    #clock {
      font-size: 15px;
      padding: 0 8px;
      color: ${text};
    }

    #cpu, #memory, #network, #bluetooth, #pulseaudio, #battery,
    #tray, #mode, #idle_inhibitor, #custom-nightlight {
      padding: 0 7px;
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

  idleCmd = pkgs.writeShellScript "niri-idle" ''
    ${pkgs.swayidle}/bin/swayidle -w \
      timeout 300 '${lockBg}' \
      timeout 300 '${niri} msg action power-off-monitors' resume '${niri} msg action power-on-monitors' \
      timeout 600 '${suspendCmd}' \
      before-sleep '${lockBg}; ${niri} msg action power-on-monitors' \
      after-resume '${niri} msg action power-on-monitors'
  '';

  workspaceNumbers = [ 1 2 3 4 5 6 7 8 9 10 ];

  workspaceBinds = lib.concatStrings (map (n:
    let
      key = if n == 10 then "0" else toString n;
    in
    ''
      ${mod}+${key} { focus-workspace ${toString n}; }
      ${mod}+Shift+${key} { spawn-sh "${moveToWorkspace (toString n)}"; }
    ''
  ) workspaceNumbers);

  kdlConfig = ''
    // Niri config ported from Sway.

    environment {
      QT_QPA_PLATFORM "wayland;xcb"
      XCURSOR_THEME "Bibata-Modern-Ice"
      XCURSOR_SIZE "20"
    }

    input {
      touchpad {
        tap
        natural-scroll
        dwt
        accel-speed -0.45
      }
      mouse {
        accel-speed 0.107296
        accel-profile "flat"
      }
    }

    output "*" {
      scale 1.5
      background-color "#191724"
    }

    layout {
      gaps 8
      struts {
        left 8
        right 8
        top 8
        bottom 8
      }
      focus-ring {
        width 0
      }
      border {
        width 1
        active-color "#6e6a86"
        inactive-color "#191724"
      }
    }

    spawn-at-startup "${systemctl}" "--user" "import-environment" "WAYLAND_DISPLAY" "XDG_CURRENT_DESKTOP" "NIRI_SOCKET"
    spawn-at-startup "${pkgs.mako}/bin/mako"
    spawn-at-startup "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"
    spawn-at-startup "${pkgs.swaybg}/bin/swaybg" "-i" "${config.home.homeDirectory}/.config/bg.jpg" "-m" "fill"
    spawn-sh-at-startup "${systemctl} --user stop waybar.service 2>/dev/null; pkill waybar 2>/dev/null; ${pkgs.waybar}/bin/waybar -c ${config.xdg.configHome}/waybar/config-niri -s ${config.xdg.configHome}/waybar/style-niri.css"
    spawn-sh-at-startup "${systemctl} --user stop swayidle.service 2>/dev/null; pkill swayidle 2>/dev/null; ${idleCmd}"

    window-rule {
      match app-id="org.gnome.Loupe"
      open-floating true
    }

    window-rule {
      match app-id="org.gnome.Nautilus"
      open-floating true
    }

    window-rule {
      match app-id="org.gnome.Nautilus" title=".*Properties"
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
      default-column-width { proportion 0.4; }
    }

    binds {
      ${mod}+Return { spawn "${terminal}"; }
      ${mod}+Z { spawn "zeditor"; }
      ${mod}+C { spawn "zeditor" "/home/anurag/Documents/nixos-config"; }
      ${mod}+S { spawn "flatpak" "run" "com.spotify.Client"; }
      ${mod}+B { spawn "flatpak" "run" "app.zen_browser.zen"; }
      ${mod}+E { spawn "nautilus"; }
      ${mod}+Space { spawn "vicinae" "toggle"; }
      ${mod}+V { spawn "vicinae" "vicinae://launch/clipboard/history"; }

      ${mod}+W { close-window; }
      ${mod}+F { fullscreen-window; }
      ${mod}+Shift+Space { toggle-window-floating; }

      ${mod}+L { spawn-sh "${lock}"; }
      ${mod}+Shift+Z { spawn-sh "${suspendCmd}"; }

      Print { spawn-sh "${shotRegion}"; }
      ${mod}+Shift+S { spawn-sh "${shotFull}"; }

      XF86AudioRaiseVolume { spawn "${swayosd-client}" "--output-volume" "raise"; }
      XF86AudioLowerVolume { spawn "${swayosd-client}" "--output-volume" "lower"; }
      XF86AudioMute { spawn "${swayosd-client}" "--output-volume" "mute-toggle"; }
      XF86AudioMicMute { spawn "${swayosd-client}" "--input-volume" "mute-toggle"; }
      XF86MonBrightnessUp { spawn "${swayosd-client}" "--brightness" "raise"; }
      XF86MonBrightnessDown { spawn "${swayosd-client}" "--brightness" "lower"; }
      XF86AudioPlay { spawn "${pkgs.playerctl}/bin/playerctl" "play-pause"; }
      XF86AudioNext { spawn "${pkgs.playerctl}/bin/playerctl" "next"; }
      XF86AudioPrev { spawn "${pkgs.playerctl}/bin/playerctl" "previous"; }

      ${mod}+Left { focus-column-left; }
      ${mod}+Right { focus-column-right; }
      ${mod}+Up { focus-window-up; }
      ${mod}+Down { focus-window-down; }

      ${mod}+Shift+Left { move-column-left; }
      ${mod}+Shift+Right { move-column-right; }
      ${mod}+Shift+Up { move-window-up; }
      ${mod}+Shift+Down { move-window-down; }

      ${workspaceBinds}
    }
  '';
in
{
  xdg.configFile."niri/config.kdl".text = kdlConfig;

  # Shared desktop services (mako, swayosd, GTK theming) are provided by
  # modules/sway-home.nix, which is also imported. Keeping them there avoids
  # duplicate-definition conflicts while both Sway and Niri are used in parallel.

  xdg.configFile."waybar/config-niri".text = waybarNiriConfig;
  xdg.configFile."waybar/style-niri.css".text = waybarNiriStyle;

  home.packages = with pkgs; [
    grim
    slurp
    brightnessctl
    playerctl
    wlsunset
  ];
}
