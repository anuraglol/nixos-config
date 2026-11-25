{ config, ... }:

{
  programs.firefox = {
    enable = true;
    # Pin the standard profile location; HM's default otherwise flips to the
    # XDG path on stateVersion >= 26.05.
    configPath = ".mozilla/firefox";

    profiles.default = {
      id = 0;
      name = "default";
      isDefault = true;

      settings = {
        "layout.css.devPixelsPerPx" = "1.0";
        "widget.use-xdg-desktop-portal.file-picker" = 1;
        "widget.wayland.overscroll.enabled" = true;
        "browser.tabs.inTitlebar" = 1;
        "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
      };

      userChrome = ''
        :root {
          --toolbar-bgcolor: ${config.omanix.activeTheme.colors.background} !important;
          --tab-selected-bgcolor: ${config.omanix.activeTheme.colors.background} !important;
          --omanix-accent: ${config.omanix.activeTheme.colors.accent};
          --omanix-fg: ${config.omanix.activeTheme.colors.foreground};
          --omanix-bg: ${config.omanix.activeTheme.colors.background};
        }

        /* Toolbar/tab bar background */
        #navigator-toolbox {
          background-color: var(--omanix-bg) !important;
        }

        /* All tabs - fully opaque */
        .tabbrowser-tab {
          opacity: 1 !important;
        }

        /* Selected/active tab - full opacity + accent underline */
        .tabbrowser-tab[selected="true"] {
          opacity: 1 !important;
        }

        /* Add accent color indicator to selected tab */
        .tabbrowser-tab[selected="true"] .tab-background {
          background: color-mix(in srgb, var(--omanix-accent) 15%, var(--omanix-bg)) !important;
          border-bottom: 2px solid var(--omanix-accent) !important;
        }

        /* Make tab text brighter on selected tab */
        .tabbrowser-tab[selected="true"] .tab-label {
          color: var(--omanix-fg) !important;
          font-weight: 500 !important;
        }

        /* Hover state for non-selected tabs */
        .tabbrowser-tab:not([selected="true"]):hover {
          opacity: 1 !important;
        }
      '';
    };
  };
}
