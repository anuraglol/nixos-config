{ lib, ... }:

{
  # Local integration: keep the option definitions (other Omanix modules may
  # introspect them) but don't touch programs.git — this flake already has its
  # own git.nix with the user's settings.
  options.omanix.user = {
    name = lib.mkOption {
      type = lib.types.str;
      description = "Git user name used for commits.";
    };
    email = lib.mkOption {
      type = lib.types.str;
      description = "Git email address used for commits.";
    };
  };
}
