{ pkgs, lib, ... }:

let
  mod = "SUPER";
  terminal = "kitty";
  lock = "${pkgs.swaylock}/bin/swaylock --color 191724ff";
  lockBg = "${pkgs.procps}/bin/pidof swaylock >/dev/null 2>&1 || ${lock} &";

  hyprctl = "${pkgs.hyprland}/bin/hyprctl";
  systemctl = "${pkgs.systemd}/bin/systemctl";
  # Always wake outputs before suspending. Suspending while Hyprland has the
  # display powered off reliably hangs s2idle on this IdeaPad/Rembrandt setup.
  suspendCmd = "${hyprctl} dispatch dpms on && ${systemctl} suspend";

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

  hx = c: lib.removePrefix "#" c;

  icon =
    let
      imod = a: b: a - (a / b) * b;
      hexChars = lib.stringToCharacters "0123456789abcdef";
      nibble = n: "${nibble' (n / 4096)}${nibble' (n / 256)}${nibble' (n / 16)}${nibble' n}";
      nibble' = n: builtins.elemAt hexChars (imod n 16);
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
      builtins.fromJSON ''"\u${nibble n}"''
    else
      let
        c = n - 65536;
        hi = 55296 + (c / 1024);
        lo = 56320 + (imod c 1024);
      in
      builtins.fromJSON ''"\u${nibble hi}\u${nibble lo}"'';

  shotFull = pkgs.writeShellScript "shot-full" ''
    ${pkgs.grim}/bin/grim - | ${pkgs.wl-clipboard}/bin/wl-copy \
      && ${pkgs.libnotify}/bin/notify-send "Screenshot" "Full screen copied to clipboard"
  '';

  shotRegion = pkgs.writeShellScript "shot-region" ''
    geom=$(${pkgs.slurp}/bin/slurp) || exit 0
    ${pkgs.grim}/bin/grim -g "$geom" - | ${pkgs.wl-clipboard}/bin/wl-copy \
      && ${pkgs.libnotify}/bin/notify-send "Screenshot" "Region copied to clipboard"
  '';

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

  workspaceNumbers = [ 1 2 3 4 5 6 7 8 9 0 ];

  workspaceBinds = map
    (n: "$mod, ${toString n}, workspace, ${toString (if n == 0 then 10 else n)}")
    workspaceNumbers;

  moveBinds = map
    (n: "$mod SHIFT, ${toString n}, movetoworkspace, ${toString (if n == 0 then 10 else n)}")
    workspaceNumbers;

  appBinds = [
    "$mod SHIFT, z, exec, ${suspendCmd}"

    "$mod, w, killactive,"
    "$mod, f, fullscreen, 1"
    "$mod SHIFT, space, togglefloating,"
    "$mod, l, exec, ${lock}"

    "$mod, RETURN, exec, ${terminal}"
    "$mod, z, exec, zeditor"
    "$mod, c, exec, zeditor /home/anurag/Documents/nixos-config"
    "$mod, s, exec, flatpak run com.spotify.Client"
    "$mod, b, exec, flatpak run app.zen_browser.zen"
    "$mod, e, exec, nautilus"

    "$mod, SPACE, exec, vicinae toggle"
    "$mod, v, exec, vicinae vicinae://launch/clipboard/history"

    ", PRINT, exec, ${shotRegion}"
    "$mod SHIFT, s, exec, ${shotFull}"

    ", XF86AudioRaiseVolume, exec, ${swayosd-client} --output-volume raise"
    ", XF86AudioLowerVolume, exec, ${swayosd-client} --output-volume lower"
    ", XF86AudioMute, exec, ${swayosd-client} --output-volume mute-toggle"
    ", XF86AudioMicMute, exec, ${swayosd-client} --input-volume mute-toggle"
    ", XF86MonBrightnessUp, exec, ${swayosd-client} --brightness raise"
    ", XF86MonBrightnessDown, exec, ${swayosd-client} --brightness lower"
    ", XF86AudioPlay, exec, playerctl play-pause"
    ", XF86AudioNext, exec, playerctl next"
    ", XF86AudioPrev, exec, playerctl previous"

    # Sway-style focus + move. mod+l is lock (matching the old Sway config),
    # so focus-right is intentionally left unbound just like it was in Sway.
    "$mod, h, movefocus, l"
    "$mod, j, movefocus, d"
    "$mod, k, movefocus, u"
    "$mod SHIFT, h, movewindow, l"
    "$mod SHIFT, j, movewindow, d"
    "$mod SHIFT, k, movewindow, u"
    "$mod SHIFT, l, movewindow, r"

    # Sway-style reload
    "$mod SHIFT, c, exec, ${hyprctl} reload"
  ];

  allBinds = workspaceBinds ++ moveBinds ++ appBinds;

  windowRules = [
    "float,class:^(org.gnome.Loupe)$"
    "float,class:^(org.gnome.Nautilus)$"
    "float,title:.*Properties,class:^(org.gnome.Nautilus)$"
    "float,title:.*(Progress|Conflict|Error|Warning).*,class:^(org.gnome.Nautilus)$"
    "float,class:^(pavucontrol)$"
    "float,windowrole:pop-up"
    "float,windowrole:bubble"
    "float,windowrole:dialog"
    "float,windowtype:dialog"
    "float,class:^(xdg-desktop-portal-gtk)$"
    "size 900 600,class:^(xdg-desktop-portal-gtk)$"
    "center,class:^(xdg-desktop-portal-gtk)$"
  ];

  execOnceCmds = [
    "${pkgs.swaybg}/bin/swaybg -i ~/.config/background -m fill"
    "${pkgs.mako}/bin/mako"
    "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"
    "${pkgs.systemd}/bin/systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP HYPRLAND_INSTANCE_SIGNATURE && ${pkgs.systemd}/bin/systemctl --user restart waybar.service swayidle.service swayosd.service vicinae.service"
  ];
in
{
  imports = [ ./waybar.nix ];

  # Keep the Home Manager Hyprland module enabled so it sets up the session
  # target/integration, but provide the actual config as a classic
  # hyprland.conf file (Hyprland 0.55.x reads .conf, not the new .lua format).
  wayland.windowManager.hyprland = {
    enable = true;
    xwayland.enable = true;
    # Suppress the "no configuration" evaluation warning; the real config lives
    # in ~/.config/hypr/hyprland.conf below.
    extraConfig = "-- real config lives in hyprland.conf\n";
  };

  xdg.configFile."hypr/hyprland.conf".text = ''
    $mod = ${mod}
    $terminal = ${terminal}
    $lock = ${lock}
    $lockBg = ${lockBg}

    # Use GNOME's wallpaper so the session looks identical to the old setup.
    monitor = ,preferred,auto,1.5

    ${lib.concatMapStringsSep "\n" (cmd: "exec-once = ${cmd}") execOnceCmds}

    env = XCURSOR_THEME,Bibata-Modern-Ice
    env = XCURSOR_SIZE,20
    env = NIXOS_OZONE_WL,1

    input {
        kb_layout = us
        follow_mouse = 1

        touchpad {
            natural_scroll = true
            tap-to-click = true
            disable-while-typing = true
        }

        accel_profile = flat
        sensitivity = 0.107296
    }

    general {
        gaps_in = 0
        gaps_out = 0
        border_size = 0
        col.active_border = rgba(${hx overlay}ee)
        col.inactive_border = rgba(${hx base}ee)
        layout = dwindle
        allow_tearing = false
    }

    decoration {
        rounding = 0
        blur {
            enabled = false
        }
        shadow {
            enabled = false
        }
    }

    animations {
        enabled = false
    }

    dwindle {
        pseudotile = true
        preserve_split = true
    }

    misc {
        disable_hyprland_logo = true
        disable_splash_rendering = true
        force_default_wallpaper = 0
    }

    ${lib.concatMapStringsSep "\n" (rule: "windowrulev2 = ${rule}") windowRules}

    ${lib.concatMapStringsSep "\n" (b: "bind = ${b}") allBinds}

    bindm = ${mod}, mouse:272, movewindow
    bindm = ${mod}, mouse:273, resizewindow

    workspace = 1, default:true

    gestures {
        workspace_swipe = true
        workspace_swipe_fingers = 3
    }
  '';

  services.swayidle = {
    enable = true;
    events = {
      # Wake the outputs before locking/suspending so we never enter s2idle
      # while Hyprland has the display powered off.
      before-sleep = "${hyprctl} dispatch dpms on; ${lockBg}";
      after-resume = "${hyprctl} dispatch dpms on";
    };
    timeouts = [
      {
        timeout = 300;
        command = lockBg;
      }
      {
        timeout = 300;
        command = "${hyprctl} dispatch dpms off";
        resumeCommand = "${hyprctl} dispatch dpms on";
      }
      {
        timeout = 600;
        command = suspendCmd;
      }
    ];
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

  home.packages = with pkgs; [
    grim
    slurp
    brightnessctl
    playerctl
    swaybg
  ];
}
