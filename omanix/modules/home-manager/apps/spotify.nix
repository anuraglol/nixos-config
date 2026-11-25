{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.omanix.apps.spotify;
in
{
  options.omanix.apps.spotify = {
    enable = lib.mkEnableOption "Spotify";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.spotify ];
  };
}
