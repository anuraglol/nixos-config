{ ... }:

{
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
}
