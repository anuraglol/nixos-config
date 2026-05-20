{ config, pkgs, ... }:
{
  home.username = "anurag";
  home.homeDirectory = "/home/anurag";
  home.stateVersion = "25.11";

  programs.home-manager.enable = true;

  home.packages = with pkgs; [
    kitty
    ghostty
    fastfetch
    fzf
    zoxide
    tmux
    wl-clipboard
    htop
    unzip
    p7zip

    mpv
    vlc
    qbittorrent
    gnome-tweaks
    bibata-cursors

    nodejs
    pnpm
    bun
    go
    gh
  ];

  programs.fish = {
    enable = true;

    shellAliases = {
      cd = "z";
      ff = "fastfetch";
    };

    interactiveShellInit = ''
      function fish_greeting
      end

      set --export BUN_INSTALL "$HOME/.bun"
      set --export PATH $BUN_INSTALL/bin $PATH

      zoxide init fish | source
    '';
  };

  programs.ghostty = {
    enable = true;
    enableFishIntegration = true;
    settings = {
      font-family = "JetBrains Mono";
      font-family-bold = "JetBrains Mono Bold";
      font-size = 12;

      window-padding-x = 10;
      window-padding-y = 10;

      background = "#1f1d2e";
      foreground = "#e0def4";
      selection-background = "#2f2c40";
      selection-foreground = "#e0def4";
      cursor-color = "#e0def4";
      cursor-text = "#1f1d2e";

      palette = [
        "0=#26233a"
        "1=#eb6f92"
        "2=#31748f"
        "3=#f6c177"
        "4=#9ccfd8"
        "5=#c4a7e7"
        "6=#ebbcba"
        "7=#e0def4"
        "8=#908caa"
        "9=#eb6f92"
        "10=#31748f"
        "11=#f6c177"
        "12=#9ccfd8"
        "13=#c4a7e7"
        "14=#ebbcba"
        "15=#e0def4"
      ];
    };
  };

  programs.zed-editor = {
    enable = true;
    userSettings = {
      icon_theme = "Zed (Default)";
      cli_default_open_behavior = "new_window";
      vim = {
        toggle_relative_line_numbers = true;
      };
      edit_predictions = {
        mode = "eager";
        provider = "copilot";
      };
      vim_mode = true;
      ui_font_size = 16;
      buffer_font_size = 14.0;
      buffer_font_family = "JetBrains Mono";
      theme = {
        mode = "dark";
        light = "One Light";
        dark = "Rosé Pine";
      };
      lsp = {
        vtsls = {
          settings = {
            typescript = {
              updateImportsOnFileMove = {
                enabled = "always";
              };
            };
            javascript = {
              updateImportsOnFileMove = {
                enabled = "always";
              };
            };
          };
          enable_lsp_tasks = true;
        };
        oxlint = {
          initialization_options = {
            settings = {
              configPath = null;
              run = "onType";
              disableNestedConfig = false;
              fixKind = "safe_fix";
              typeAware = true;
              unusedDisableDirectives = "deny";
            };
          };
        };
        oxfmt = {
          initialization_options = {
            settings = {
              "fmt.configPath" = null;
              run = "onSave";
            };
          };
        };
      };
      languages = {
        CSS = {
          format_on_save = "on";
          prettier = {
            allowed = false;
          };
          formatter = [
            {
              language_server = {
                name = "oxfmt";
              };
            }
          ];
        };
        GraphQL = {
          format_on_save = "on";
          prettier = {
            allowed = false;
          };
          formatter = [
            {
              language_server = {
                name = "oxfmt";
              };
            }
          ];
        };
        HTML = {
          format_on_save = "on";
          prettier = {
            allowed = false;
          };
          formatter = [
            {
              language_server = {
                name = "oxfmt";
              };
            }
          ];
        };
        JavaScript = {
          format_on_save = "on";
          prettier = {
            allowed = false;
          };
          formatter = [
            {
              language_server = {
                name = "oxfmt";
              };
            }
            { code_action = "source.fixAll.oxc"; }
          ];
        };
        JSON = {
          format_on_save = "on";
          prettier = {
            allowed = false;
          };
          formatter = [
            {
              language_server = {
                name = "oxfmt";
              };
            }
          ];
        };
        JSONC = {
          format_on_save = "on";
          prettier = {
            allowed = false;
          };
          formatter = [
            {
              language_server = {
                name = "oxfmt";
              };
            }
          ];
        };
        Less = {
          format_on_save = "on";
          prettier = {
            allowed = false;
          };
          formatter = [
            {
              language_server = {
                name = "oxfmt";
              };
            }
          ];
        };
        Markdown = {
          format_on_save = "on";
          prettier = {
            allowed = false;
          };
          formatter = [
            {
              language_server = {
                name = "oxfmt";
              };
            }
          ];
        };
        MDX = {
          format_on_save = "on";
          prettier = {
            allowed = false;
          };
          formatter = [
            {
              language_server = {
                name = "oxfmt";
              };
            }
          ];
        };
        SCSS = {
          format_on_save = "on";
          prettier = {
            allowed = false;
          };
          formatter = [
            {
              language_server = {
                name = "oxfmt";
              };
            }
          ];
        };
        TypeScript = {
          format_on_save = "on";
          prettier = {
            allowed = false;
          };
          formatter = [
            {
              language_server = {
                name = "oxfmt";
              };
            }
          ];
        };
        TSX = {
          format_on_save = "on";
          prettier = {
            allowed = false;
          };
          formatter = [
            {
              language_server = {
                name = "oxfmt";
              };
            }
          ];
        };
        "Vue.js" = {
          format_on_save = "on";
          prettier = {
            allowed = false;
          };
          formatter = [
            {
              language_server = {
                name = "oxfmt";
              };
            }
          ];
        };
        YAML = {
          format_on_save = "on";
          prettier = {
            allowed = false;
          };
          formatter = [
            {
              language_server = {
                name = "oxfmt";
              };
            }
          ];
        };
      };
    };
  };

  programs.fastfetch = {
    enable = true;
    settings = {
      "$schema" = "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json";
      modules = [
        "break"
        {
          type = "custom";
          format = "\\u001b[90m┌──────────────────────Hardware──────────────────────┐";
        }
        {
          type = "host";
          key = " PC";
          keyColor = "green";
        }
        {
          type = "cpu";
          key = "│ ├";
          showPeCoreCount = true;
          keyColor = "green";
        }
        {
          type = "gpu";
          key = "│ ├";
          detectionMethod = "pci";
          keyColor = "green";
        }
        {
          type = "display";
          key = "│ ├󱄄";
          keyColor = "green";
        }
        {
          type = "disk";
          key = "│ ├󰋊";
          keyColor = "green";
        }
        {
          type = "memory";
          key = "│ ├";
          keyColor = "green";
        }
        {
          type = "swap";
          key = "└ └󰓡 ";
          keyColor = "green";
        }
        {
          type = "custom";
          format = "\\u001b[90m└────────────────────────────────────────────────────┘";
        }
        "break"
        {
          type = "custom";
          format = "\\u001b[90m┌──────────────────────Software──────────────────────┐";
        }
        {
          type = "os";
          key = " OS";
          keyColor = "blue";
        }
        {
          type = "kernel";
          key = "│ ├";
          keyColor = "blue";
        }
        {
          type = "wm";
          key = "│ ├";
          keyColor = "blue";
        }
        {
          type = "terminal";
          key = "│ ├";
          keyColor = "blue";
        }
        {
          type = "packages";
          key = "│ ├󰏖";
          keyColor = "blue";
        }
        {
          type = "wmtheme";
          key = "│ ├󰉼";
          keyColor = "blue";
        }
        {
          type = "terminalfont";
          key = "└ └";
          keyColor = "blue";
        }
        {
          type = "custom";
          format = "\\u001b[90m└────────────────────────────────────────────────────┘";
        }
        "break"
        {
          type = "custom";
          format = "\\u001b[90m┌────────────────Age / Uptime / Update───────────────┐";
        }
        {
          type = "command";
          key = "󱦟 OS Age";
          keyColor = "magenta";
          text = "echo $(( ($(date +%s) - $(stat -c %W /)) / 86400 )) days";
        }
        {
          type = "uptime";
          key = "󱫐 Uptime";
          keyColor = "magenta";
        }
        {
          type = "custom";
          format = "\\u001b[90m└────────────────────────────────────────────────────┘";
        }
        "break"
      ];
    };
  };
}
