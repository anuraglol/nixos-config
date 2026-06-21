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
      please = "sudo $history[1]";
      cl = "clear";
      sys-rebuild = "sudo nixos-rebuild switch --flake ~/Documents/nixos-config#neko";
      pc = "nix run nixpkgs#process-compose -- -f process-compose.yaml";
      fupdate = "nix flake update --flake ~/Documents/nixos-config";
      tnux = "tmux -u";
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
