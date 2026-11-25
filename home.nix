{
  pkgs,
  vicinae,
  helium-flake,
  sidra,
  omanix,
  config,
  lib,
  ...
}:

let
  # Text-only RAM/CPU bar widget. Built from inline sources so it is fully
  # pure: no external checkout, no script, no FHS paths to patch.
  ramCpuManifest = pkgs.writeText "local-ram-cpu-manifest.json" (
    builtins.toJSON {
      schemaVersion = 1;
      id = "local.ram-cpu";
      name = "RAM / CPU text monitor";
      version = "1.0.0";
      description = "Text-only RAM and CPU readouts for the Omanix bar.";
      kinds = [ "bar-widget" ];
      entryPoints.barWidget = "Widget.qml";
      barWidget = {
        displayName = "RAM / CPU";
        description = "RAM used/total in GiB and CPU utilisation in percent.";
        category = "System";
        allowMultiple = false;
        defaultSection = "right";
        defaults = { };
        schema = [ ];
      };
    }
  );

  ramCpuWidget = pkgs.writeText "local-ram-cpu-Widget.qml" ''
    import QtQuick
    import Quickshell.Io
    import qs.Commons
    import qs.Ui

    BarWidget {
      id: root
      moduleName: "local.ram-cpu"

      property string ramText: "--/--G"
      property string cpuText: "--%"
      property var previousCpu: null

      readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family

      function firstNumber(line) {
        var s = String(line)
        var out = ""
        var started = false
        for (var i = 0; i < s.length; ++i) {
          var c = s.charAt(i)
          if (c >= "0" && c <= "9") {
            started = true
            out += c
          } else if (started) {
            break
          }
        }
        return out === "" ? NaN : Number(out)
      }

      function applyMemory(raw) {
        var total = NaN
        var available = NaN
        var lines = String(raw).split("\n")
        for (var i = 0; i < lines.length; ++i) {
          if (lines[i].indexOf("MemTotal:") === 0) total = firstNumber(lines[i])
          if (lines[i].indexOf("MemAvailable:") === 0) available = firstNumber(lines[i])
        }
        if (!isFinite(total) || !isFinite(available) || total <= 0) return
        var gib = 1048576
        var used = Math.max(0, total - available)
        root.ramText = (used / gib).toFixed(1) + "/" + (total / gib).toFixed(1) + "G"
      }

      function cpuJiffies(raw) {
        var lines = String(raw).split("\n")
        for (var i = 0; i < lines.length; ++i) {
          if (lines[i].indexOf("cpu ") !== 0) continue
          var fields = lines[i].split(" ")
          var values = []
          for (var j = 1; j < fields.length; ++j) {
            if (fields[j] === "") continue
            var n = Number(fields[j])
            if (isFinite(n)) values.push(n)
          }
          return values.length >= 5 ? values : null
        }
        return null
      }

      function applyCpu(raw) {
        var now = cpuJiffies(raw)
        if (!now) return
        var prev = root.previousCpu
        root.previousCpu = now
        if (!prev || prev.length !== now.length) return
        var totalNow = 0
        var idleNow = 0
        var totalPrev = 0
        var idlePrev = 0
        for (var i = 0; i < now.length; ++i) {
          totalNow += now[i]
          totalPrev += prev[i]
          if (i === 3 || i === 4) {
            idleNow += now[i]
            idlePrev += prev[i]
          }
        }
        var deltaTotal = totalNow - totalPrev
        var deltaIdle = idleNow - idlePrev
        if (deltaTotal <= 0) return
        var usage = 100 * (1 - deltaIdle / deltaTotal)
        root.cpuText = Math.max(0, Math.min(100, Math.round(usage))) + "%"
      }

      function sample() {
        memFile.reload()
        root.applyMemory(memFile.text())
        statFile.reload()
        root.applyCpu(statFile.text())
      }

      FileView {
        id: memFile
        path: "/proc/meminfo"
        blockAllReads: true
        printErrors: false
      }

      FileView {
        id: statFile
        path: "/proc/stat"
        blockAllReads: true
        printErrors: false
      }

      Component.onCompleted: root.sample()

      Timer {
        interval: 400
        running: true
        repeat: false
        onTriggered: root.sample()
      }

      Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: root.sample()
      }

      implicitWidth: button.implicitWidth
      implicitHeight: button.implicitHeight

      WidgetButton {
        id: button
        anchors.fill: parent
        bar: root.bar
        labelVisible: false
        hasVisualContent: true
        interactive: false
        pressable: false
        // Match the exact whitespace between two adjacent bar icons:
        // (icon slot - icon canvas) / 2 on each outer edge.
        horizontalMargin: (Style.bar.iconSlot - Style.bar.iconCanvas) / 2
        fixedWidth: root.vertical ? -1 : Math.ceil(readouts.implicitWidth + button.scaledHorizontalMargin * 2)
        fixedHeight: root.vertical ? Style.bar.iconSlot : -1

        Row {
          id: readouts
          anchors.centerIn: parent
          // Same gap as one icon slot's whitespace around its glyph.
          spacing: Style.bar.iconSlot - Style.bar.iconCanvas

          Text {
            text: "RAM " + root.ramText
            color: button.foreground
            font.family: root.fontFamily
            font.pixelSize: Style.font.body
            renderType: Text.NativeRendering
            anchors.verticalCenter: parent.verticalCenter
          }

          Text {
            text: "CPU " + root.cpuText
            color: button.foreground
            font.family: root.fontFamily
            font.pixelSize: Style.font.body
            renderType: Text.NativeRendering
            anchors.verticalCenter: parent.verticalCenter
          }
        }
      }
    }
  '';

  ramCpuPlugin = pkgs.runCommand "local-ram-cpu-plugin" { } ''
    mkdir -p "$out"
    cp ${ramCpuManifest} "$out/manifest.json"
    cp ${ramCpuWidget} "$out/Widget.qml"
  '';
in
{
  # The user channel allows unfree packages (obsidian, slack, steam, etc.).
  nixpkgs.config.allowUnfree = true;
  # Omanix's Home Manager modules expect its packages (omanix-shell, wlctl,
  # etc.). HM uses its own pkgs instance, so the overlay must be added here too.
  nixpkgs.overlays = [
    helium-flake.overlays.default
    omanix.overlays.default
  ];

  imports = [
    ./modules/packages.nix
    ./modules/fish.nix
    ./modules/zed-editor.nix
    ./modules/kitty.nix
    ./modules/git.nix
    ./modules/mpv.nix
    ./modules/dconf.nix
    vicinae.homeManagerModules.default
    omanix.homeManagerModules.default
  ];

  home.username = "anurag";
  home.homeDirectory = "/home/anurag";
  home.stateVersion = "26.05";

  programs.home-manager.enable = true;
  programs.kitty.enable = true;

  gtk = {
    enable = true;

    # Applies to GTK2/GTK3 and gets mirrored into dconf as 'prefer-dark'.
    colorScheme = "dark";

    theme = {
      name = "Adwaita-dark";
      package = pkgs.gnome-themes-extra;
    };

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

    # GNOME's Adwaita-dark is a GTK3 theme only. GTK4 has built-in Adwaita
    # with a dark variant, which is selected by the settings below.
    gtk4 = {
      theme = null;

      # Home Manager writes gtk-interface-color-scheme as a number, but GTK
      # 4.20+ parses this enum from nicknames and rejects numeric values.
      # Write the valid string form ourselves instead.
      colorScheme = null;

      extraConfig = {
        gtk-application-prefer-dark-theme = true;
        gtk-interface-color-scheme = "dark";
        gtk-xft-antialias = 1;
        gtk-xft-hinting = 1;
        gtk-xft-hintstyle = "hintfull";
        gtk-xft-rgba = "rgb";
      };

      # Nautilus 50 adds .nautilus-window to its real window, so these rules
      # stay scoped to Files and leave other GTK4/libadwaita apps untouched.
      # This is normal GTK4 user CSS, not a patched theme or a Nix store edit.
      extraCss = ''
        /* Compact, traditional dark file-chooser-like styling for Nautilus. */
        .nautilus-window {
          --window-bg-color: #1e1e20;
          --view-bg-color: #1e1e20;
          --headerbar-bg-color: #303034;
          --headerbar-backdrop-color: #303034;
          --headerbar-shade-color: #45454a;
          --headerbar-darker-shade-color: #45454a;
          --headerbar-border-color: #45454a;
          --sidebar-bg-color: #303034;
          --sidebar-backdrop-color: #303034;
          --sidebar-border-color: #45454a;
          --sidebar-shade-color: #45454a;
          --secondary-sidebar-bg-color: #2a2a2e;
          --window-fg-color: #eeeeee;
          --view-fg-color: #eeeeee;
          --headerbar-fg-color: #eeeeee;
          --sidebar-fg-color: #eeeeee;
          --secondary-sidebar-fg-color: #eeeeee;
          --border-color: #45454a;
          --dim-opacity: 70%;
          --window-radius: 6px;

          font-family: "JetBrains Mono";
          font-size: 11pt;
          font-weight: 400;
        }

        .nautilus-window headerbar {
          min-height: 36px;
          background-color: #303034;
          color: #eeeeee;
          box-shadow: inset 0 -1px #45454a;
          border-radius: 0;
        }

        .nautilus-window headerbar button,
        .nautilus-window headerbar menubutton > button {
          min-width: 24px;
          min-height: 24px;
          padding: 3px 6px;
          border-radius: 4px;
          font-family: "JetBrains Mono";
          font-size: 11pt;
          font-weight: 400;
        }

        .nautilus-window headerbar button.pill,
        .nautilus-window headerbar menubutton.pill > button {
          padding: 3px 8px;
          border-radius: 4px;
        }

        .nautilus-window headerbar button:hover,
        .nautilus-window headerbar menubutton > button:hover {
          background-color: #39393e;
        }

        .nautilus-window headerbar button:checked,
        .nautilus-window headerbar menubutton > button:checked {
          background-color: #414148;
        }

        .nautilus-window headerbar windowtitle label {
          color: #eeeeee;
          font-size: 11pt;
          font-weight: 400;
        }

        .nautilus-window placessidebar {
          background-color: #303034;
          color: #eeeeee;
        }

        .nautilus-window placessidebar .navigation-sidebar > row {
          min-height: 28px;
          margin: 0 4px 1px;
          padding: 0 6px;
          border-radius: 6px;
          font-family: "JetBrains Mono";
          font-size: 11pt;
          font-weight: 400;
        }

        .nautilus-window placessidebar .navigation-sidebar > row > revealer {
          padding: 0 8px;
        }

        .nautilus-window placessidebar .navigation-sidebar > row image.sidebar-icon {
          -gtk-icon-size: 14px;
          min-width: 14px;
          min-height: 14px;
        }

        .nautilus-window placessidebar .navigation-sidebar > row label {
          color: #eeeeee;
          font-size: 11pt;
          font-weight: 400;
        }

        .nautilus-window placessidebar .navigation-sidebar > row label.dim-label {
          color: #a5a5a5;
          opacity: 1;
        }

        .nautilus-window placessidebar .navigation-sidebar > row:hover {
          background-color: #39393e;
        }

        .nautilus-window placessidebar .navigation-sidebar > row:selected {
          background-color: #414148;
          color: #eeeeee;
        }

        .nautilus-window placessidebar .navigation-sidebar > row:selected:hover {
          background-color: #414148;
        }

        .nautilus-window placessidebar .navigation-sidebar > row:selected:active {
          box-shadow: none;
        }

        .nautilus-window .nautilus-pathbar {
          background-color: #303034;
          border-radius: 4px;
          box-shadow: inset 0 0 0 1px #45454a;
        }

        .nautilus-window .nautilus-path-button {
          min-height: 24px;
          margin: 1px 2px;
          padding: 1px 6px;
          border-radius: 4px;
          color: #eeeeee;
          font-family: "JetBrains Mono";
          font-size: 11pt;
          font-weight: 400;
        }

        .nautilus-window .nautilus-path-button.current-dir {
          color: #eeeeee;
          font-weight: 400;
        }

        .nautilus-window .view,
        .nautilus-window .nautilus-grid-view gridview {
          background-color: #1e1e20;
          color: #eeeeee;
        }

        .nautilus-window .nautilus-grid-view gridview {
          padding: 8px;
          border-spacing: 4px;
        }

        .nautilus-window .nautilus-grid-view gridview > child {
          padding: 2px;
          border-radius: 6px;
        }

        .nautilus-window .nautilus-grid-view .nautilus-view-cell {
          padding: 4px;
          border-radius: 6px;
        }

        .nautilus-window .nautilus-grid-view gridview > child:hover {
          background-color: #39393e;
        }

        .nautilus-window .nautilus-grid-view gridview > child:selected {
          background-color: #414148;
          outline-color: #45454a;
        }

        .nautilus-window .nautilus-grid-view label,
        .nautilus-window .nautilus-list-view label {
          color: #eeeeee;
          font-family: "JetBrains Mono";
          font-size: 11pt;
          font-weight: 400;
        }

        .nautilus-window .nautilus-grid-view .caption,
        .nautilus-window .nautilus-list-view .caption,
        .nautilus-window .dim-label {
          color: #a5a5a5;
          opacity: 1;
        }

        .nautilus-window .nautilus-list-view columnview > listview {
          padding-top: 6px;
          padding-bottom: 6px;
          margin-left: -12px;
          margin-right: -12px;
          border-spacing: 2px;
        }

        .nautilus-window .nautilus-list-view columnview > listview > row {
          min-height: 28px;
          margin-left: 12px;
          margin-right: 12px;
          border-radius: 4px;
        }

        .nautilus-window .nautilus-list-view columnview > listview > row:hover {
          background-color: #39393e;
        }

        .nautilus-window .nautilus-list-view columnview > listview > row:selected {
          background-color: #414148;
        }

        .nautilus-window .floating-bar {
          background-color: #1e1e20;
          border-radius: 6px;
        }

        .nautilus-window .toolbar.no-bottom-padding {
          padding-bottom: 0;
        }
      '';
    };
  };

  dconf = {
    enable = true;

    settings = {
      "org/gnome/desktop/interface" = {
        color-scheme = "prefer-dark";
        accent-color = "blue";
      };
    };
  };

  # Home Manager's Hyprland module points NIX_XDG_DESKTOP_PORTAL_DIR at the
  # user profile and only puts the Hyprland backend there. That backend does
  # not implement org.freedesktop.portal.Settings, so libadwaita apps
  # (Nautilus, Boxes, Bottles...) never learn about the dark preference and
  # fall back to light. Mirror the NixOS portal setup into the user profile.
  xdg.portal = {
    enable = true;
    extraPortals = lib.mkForce (with pkgs; [
      xdg-desktop-portal-wlr
      xdg-desktop-portal-gtk
      xdg-desktop-portal-gnome
      xdg-desktop-portal-hyprland
    ]);
    config = {
      common = {
        default = [ "wlr" ];
        # xdg-desktop-portal-gtk is still GTK3, so it gives browsers the
        # traditional GtkFileChooserDialog. Keep Settings on GNOME portal so
        # GTK4/libadwaita apps still receive the dark color scheme.
        "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
        "org.freedesktop.impl.portal.Settings" = [ "gnome" ];
      };
      hyprland = {
        default = [ "gnome" ];
        # GNOME portal needs mutter for these; keep them on Hyprland.
        "org.freedesktop.impl.portal.ScreenCast" = [ "hyprland" ];
        "org.freedesktop.impl.portal.ScreenShot" = [ "hyprland" ];
        "org.freedesktop.impl.portal.GlobalShortcuts" = [ "hyprland" ];
      };
    };
    xdgOpenUsePortal = true;
  };

  # Omanix (Hyprland) session settings.
  omanix = {
    idle.screensaver.enable = false;

    monitor.scale = "1.5";
    monitor.textSize = 14;
    terminal.emulator = "kitty";

    hyprland = {
      gaps.inner = 0;
      blur.enabled = false;
      gaps.outer = 0;
      border.size = 0;
      animations.enabled = false;

      # Mirrors modules/dconf.nix input settings. GNOME's speed scale (-1..1)
      # isn't the same as Hyprland's multiplier, so 0.107296 -> 1.1 and
      # -0.3 -> 0.7 are close practical equivalents.
      extraSettings = {
        config.input = {
          mouse = {
            # sensitivity = 1.1;
          };
          touchpad = {
            # sensitivity = 0.7;
            tap_to_click = true;
            disable_while_typing = true;
            natural_scroll = true;
          };
        };
      };

      # App launchers. Appended after Omanix defaults so these win on conflicts.
      extraBindings = [
        {
          _args = [
            (lib.generators.mkLuaInline ''mod .. " + B"'')
            (lib.generators.mkLuaInline "hl.dsp.exec_cmd([[helium]])")
            { description = "Open Helium"; }
          ];
        }
        {
          _args = [
            (lib.generators.mkLuaInline ''mod .. " + Z"'')
            (lib.generators.mkLuaInline "hl.dsp.exec_cmd([[zeditor]])")
            { description = "Open Zed"; }
          ];
        }
        {
          _args = [
            (lib.generators.mkLuaInline ''mod .. " + C"'')
            (lib.generators.mkLuaInline "hl.dsp.exec_cmd([[zeditor /home/anurag/Documents/nixos-config]])")
            { description = "Open NixOS config in Zed"; }
          ];
        }
        {
          _args = [
            (lib.generators.mkLuaInline ''mod .. " + E"'')
            (lib.generators.mkLuaInline "hl.dsp.exec_cmd([[nautilus --new-window /home/anurag/Downloads]])")
            { description = "Open Files in Downloads"; }
          ];
        }
      ];
    };

    quickshell = {
      # Bar widgets are enabled by their bar.layout entry, not by plugins[].
      plugins = {
        "local.ram-cpu" = {
          source = ramCpuPlugin;
          enable = false;
        };
      };

      # Reproduce Omanix's default right section with the custom text widget
      # immediately before Bluetooth. Arrays are replaced wholesale on
      # reconcile, so every default entry (and the opt-in AI one) is listed.
      bar.layout.right = [
        {
          id = "omanix.indicators";
          items = [
            "ScreenRecording"
            "Dnd"
            "StayAwake"
          ];
        }
        { id = "omanix.tray"; }
        { id = "local.ram-cpu"; }
        { id = "omanix.bluetooth"; }
        { id = "omanix.network"; }
        { id = "omanix.audio"; }
        { id = "omanix.monitor"; }
        {
          id = "omanix.power";
          showPercentage = true;
        }
      ] ++ lib.optionals config.omanix.apps.ai.usageWidget.enable [
        {
          id = "omanix.agents";
          refreshIntervalSec = config.omanix.apps.ai.usageWidget.refreshIntervalSec;
          providers = {
            claude = { enabled = config.omanix.apps.ai.usageWidget.providers.claude; };
            codex = { enabled = config.omanix.apps.ai.usageWidget.providers.codex; };
            fireworks = { enabled = config.omanix.apps.ai.usageWidget.providers.fireworks; };
          };
        }
      ];
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

  services.ssh-agent.enable = true;
  programs.ssh = {
    enable = true;
    settings."*" = {
      AddKeysToAgent = "yes";
    };
  };

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
        opacity = 1.0;
      };
    };
  };
}
