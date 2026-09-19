{ pkgs, ... }:

let
  base = "#191724";
  surface = "#1f1d2e";
  text = "#e0def4";
  muted = "#6e6a86";
  iris = "#c4a7e7";
  love = "#eb6f92";
  foam = "#9ccfd8";
  gold = "#f6c177";

  icon =
    let
      imod = a: b: a - (a / b) * b;
      hexChars = pkgs.lib.stringToCharacters "0123456789abcdef";
      nibble = n: builtins.elemAt hexChars (imod n 16);
      toHex4 = n: "${nibble (n / 4096)}${nibble (n / 256)}${nibble (n / 16)}${nibble n}";
      hexVal = {
        "0" = 0; "1" = 1; "2" = 2; "3" = 3; "4" = 4;
        "5" = 5; "6" = 6; "7" = 7; "8" = 8; "9" = 9;
        "a" = 10; "b" = 11; "c" = 12; "d" = 13; "e" = 14; "f" = 15;
      };
      hexToInt =
        s: pkgs.lib.foldl' (acc: c: acc * 16 + hexVal.${c}) 0 (pkgs.lib.stringToCharacters (pkgs.lib.toLower s));
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
in
{
  programs.waybar = {
    enable = true;
    systemd.enable = true;
    settings.mainBar = {
      layer = "top";
      position = "top";
      height = 28;
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
        format = "{name}";
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
        format-alt = "{:%a %d %b %Y %H:%M}";
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

    style = ''
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
  };
}
