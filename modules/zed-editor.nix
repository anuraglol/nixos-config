{ unstable-pkgs, ... }:

{
  programs.zed-editor = {
    enable = true;
    package = unstable-pkgs.zed-editor;
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
}
