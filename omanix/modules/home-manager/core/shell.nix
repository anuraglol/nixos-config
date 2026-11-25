{ pkgs, config, lib, ... }:

{
  # Local integration: Omanix upstream hard-wires zsh (oh-my-zsh, zsh fzf /
  # direnv / starship hooks). This flake uses fish, so those hooks are replaced
  # with their fish equivalents and the oh-my-zsh/zsh prompt setup is dropped.
  options.omanix.shell = {
    dirhistory = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Deprecated zsh-only option; no effect in the fish-based local integration.";
    };
  };

  config = {
    programs = {
      direnv = {
        enable = true;
        nix-direnv.enable = true;
        enableFishIntegration = true;
      };

      fish = {
        enable = true;

        # Merge with the aliases already defined in modules/fish.nix.
        shellAliases = {
          ls = "eza -lh --group-directories-first --icons=auto";
          lt = "eza --tree --level=2 --long --icons --git";
          ll = "eza -l --icons=auto";
          la = "eza -la --icons=auto";
          pbcopy = "wl-copy --type text/plain";
          pbpaste = "wl-paste";
          cat = "bat -pp";
        };
      };

      fzf = {
        enable = true;
        enableFishIntegration = true;
      };
    };

    # Omanix scripts/terminals expect these; they apply to every shell.
    home.sessionVariables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
      TERMINAL = config.omanix.terminal.bin;
    };

    home.packages = with pkgs; [
      eza
      ripgrep
      fd
      fzf
      _7zz
      file
      yt-dlp
    ];
  };
}
