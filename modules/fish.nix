{ ... }:

{
  programs.fish = {
    enable = true;

    shellAliases = {
      cd = "z";
      ff = "fastfetch";
      zed = "zeditor . && exit";
      zede = "zeditor . &";

      npx = "nlx";
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
