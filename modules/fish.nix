{ ... }:

{
  programs.fish = {
    enable = true;

    shellAliases = {
      cd = "z";
      ff = "fastfetch";

      # ni = "ni";
      # npi = "ni";
      # "npm install" = "ni";
      # "npm i" = "ni";

      # "npm install -g" = "nig";
      # "npm i -g" = "nig";

      # "npm install -D" = "nid";
      # "npm i -D" = "nid";
      # "npm install --save-dev" = "nid";

      # "npm uninstall" = "nun";
      # "npm rm" = "nun";

      # "npm run" = "nr";
      # "npm run dev" = "nr dev";
      # "npm run build" = "nr build";
      # "npm test" = "nt";
      # "npm t" = "nt";

      # npx = "nlx";

      # "npm update" = "nu";
    };

    interactiveShellInit = ''
      function fish_greeting
      end

      functions --copy fish_prompt original_fish_prompt
      function fish_prompt
        original_fish_prompt
        if set -q IN_NIX_SHELL
          set_color -o blue
          echo -n "❄️ [nix] "
          set_color normal
        end
      end

      set --export BUN_INSTALL "$HOME/.bun"
      set --export PATH $BUN_INSTALL/bin $PATH

      zoxide init fish | source
    '';
  };
}
