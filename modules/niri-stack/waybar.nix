# Waybar config translated from the donor repo's home-manager/config/waybar/config.
{ lib, config, ... }:

lib.mkIf config.niriStack.enable {
  home-manager.users.anurag.programs.waybar = {
    enable = true;
    systemd.enable = lib.mkForce false;
    settings.mainBar = lib.mkForce {
      layer = "top";
      position = "top";
      height = 28;
      spacing = 0;
      modules-left = [ "niri/workspaces" "niri/window" ];
      modules-right = [ "network" "battery" "pulseaudio" "tray" "clock" ];

      "niri/workspaces" = {
        format = "{icon}";
        format-icons = {
          active = "";
          default = "";
        };
      };
      "niri/window" = {
        format = "  {app_id}";
        rewrite = {
          "(.*) - Mozilla Firefox" = "🌎 $1";
          "(.*) - zsh" = "> [$1]";
        };
      };
      tray = { spacing = 12; tooltip = false; };
      clock = { format = "󰅐 {:%H:%M}"; tooltip = false; };
      network = {
        format-wifi = "  {bandwidthDownBits}";
        format-ethernet = "  {bandwidthDownBits}";
        format-disconnected = "󰤮 wifiless?";
        interval = 10;
        tooltip = true;
      };
      pulseaudio = {
        scroll-step = 1;
        max-volume = 150;
        format = "{icon} {volume}%";
        format-bluetooth = "{icon} {volume}%";
        format-icons = [ "" "" " " ];
        nospacing = 1;
        format-muted = " ";
        on-click = "pavucontrol";
        tooltip = false;
      };
      battery = {
        states.warning = 30;
        states.critical = 15;
        format = "{icon} {capacity}%";
        format-charging = "󰂄 {capacity}%";
        format-plugged = "󰂄{capacity}%";
        format-alt = "{icon} {time}";
        format-full = "󱈑 {capacity}%";
        format-icons = [ "󱊡" "󱊢" "󱊣" ];
        tooltip = true;
        interval = 10;
      };
    };
    style = lib.mkForce (builtins.readFile ./assets/waybar/style.css);
  };
}
