{ config, lib, pkgs, ... }:
let
  niriExe = lib.getExe config.programs.niri.package;
  lock = "${lib.getExe pkgs.swaylock} -f --color 191724ff";
  suspend = "${niriExe} msg action power-on-monitors; ${lib.getExe' pkgs.systemd "systemctl"} suspend";
in
lib.mkIf config.niriStack.enable {
  home-manager.users.anurag = {
    xdg.configFile."wlogout".source = ./assets/wlogout;

    services.swayidle = {
      enable = true;
      events = {
        before-sleep = "${niriExe} msg action power-on-monitors; ${lock}";
        lock = lock;
      };
      timeouts = [
        { timeout = 300; command = lock; }
        { timeout = 600; command = suspend; }
      ];
    };
  };
}
