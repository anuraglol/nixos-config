{ pkgs, ... }:

{
  programs.git = {
    enable = true;

    settings = {
      user = {
        name = "Anurag";
        email = "kr.anurag24@gmail.com";
      };

      init.defaultBranch = "main";

      push.autoSetupRemote = true;

      core = {
        editor = "nvim";
        whitespace = "fix,-indent-with-non-tab,trailing-space,cr-at-eol";
      };

      pull.rebase = true;

      fetch.prune = true;

      diff.algorithm = "histogram";

      merge.conflictstyle = "zdiff3";

      rerere = {
        enabled = true;
        autoupdate = true;
      };

      column.ui = "auto";

      branch.sort = "-committerdate";

      alias = {
        st = "status";
        co = "checkout";
        br = "branch";
        cm = "commit -m";
        ca = "commit --amend --no-edit";
        lg = "log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold green)(%ar)%C(reset) %C(white)%s%C(reset) %C(dim white)- %an%C(reset)%C(bold yellow)%d%C(reset)' --all";
      };
    };
  };

  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      navigate = true;
      light = false;
      side-by-side = true;
      line-numbers = true;
    };
  };
}
