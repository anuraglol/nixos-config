{ pkgs, ... }:

{
  programs.zed-editor = {
    enable = true;
    package = pkgs.zed-editor;
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
      theme = "Vitesse Refined Dark";
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
    };
  };
}
