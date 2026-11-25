{
  config,
  pkgs,
  alt-pkgs,
  lib,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
    ./modules/hardware.nix
    ./modules/greeter.nix
  ];

  boot.loader = {
    systemd-boot.enable = true;
    efi = {
      canTouchEfiVariables = true;
    };
    timeout = 1;
    systemd-boot.configurationLimit = 10;
  };

  hardware.amdgpu.initrd.enable = true;

  networking.hostName = "neko";

  time.timeZone = "Asia/Kolkata";
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_IN";
    LC_IDENTIFICATION = "en_IN";
    LC_MEASUREMENT = "en_IN";
    LC_MONETARY = "en_IN";
    LC_NAME = "en_IN";
    LC_NUMERIC = "en_IN";
    LC_PAPER = "en_IN";
    LC_TELEPHONE = "en_IN";
    LC_TIME = "en_IN";
  };

  systemd.services.display-manager.restartIfChanged = false;

  services.printing.enable = false;
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };
  services.mysql = {
    enable = true;
    package = pkgs.mariadb;
  };

  services.fwupd.enable = true;

  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_16;

    authentication = pkgs.lib.mkOverride 10 ''
      local all all trust
      host all all 127.0.0.1/32 trust
      host all all ::1/128 trust
    '';
  };

  services.tailscale = {
    enable = false;
  };

  services.redis.servers.local = {
    enable = true;
    port = 6379;
  };

  services.power-profiles-daemon.enable = true;
  services.upower.enable = true;

  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
  };

  services.usbmuxd.enable = true;
  services.gvfs.enable = true;

  services.flatpak.enable = true;
  networking.networkmanager.enable = true;

  # services.resolved.enable = false;
  virtualisation.docker = {
    enable = true;
  };

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 53317 ];
    allowedUDPPorts = [ 53317 ];
  };

  programs.steam = {
    enable = true;
    extraCompatPackages = with pkgs; [
      proton-ge-bin
    ];
  };
  programs.gamemode.enable = true;

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = true;
    };
  };

  users.users.anurag = {
    isNormalUser = true;
    description = "anurag";
    extraGroups = [
      "networkmanager"
      "wheel"
      "docker"
      "render"
    ];
    packages = with pkgs; [ ];
    shell = pkgs.fish;
  };

  programs.firefox = {
    enable = true;
    package = alt-pkgs.firefox;
  };
  programs.fish.enable = true;
  programs.yazi = {
    enable = true;
    package = alt-pkgs.yazi;
  };

  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    # Add any common missing libraries here if the app crashes later
  ];
  programs.appimage = {
    enable = true;
    binfmt = true;
  };

  # Ly is the login manager (see modules/greeter.nix); the GNOME session is
  # deliberately not installed. GNOME apps, portal and theme support stay.
  services.desktopManager.gnome.enable = lib.mkForce false;
  services.displayManager.defaultSession = "hyprland";

  # services.nextdns = {
  #   enable = true;
  #   arguments = [
  #     "-profile"
  #     "38a36c"
  #     "-cache-size"
  #     "10MB"
  #   ];
  # };
  xdg.portal = {
    enable = true;
    wlr.enable = true;

    extraPortals = [
      pkgs.xdg-desktop-portal-wlr
      pkgs.xdg-desktop-portal-gtk
      pkgs.xdg-desktop-portal-gnome
      pkgs.xdg-desktop-portal-hyprland
    ];
    config.common.default = [
      "wlr"
    ];
    config.common."org.freedesktop.impl.portal.FileChooser" = [ "gnome" ];
    config.hyprland.default = [
      "gnome"
    ];
    xdgOpenUsePortal = true;
  };

  qt = {
    enable = true;
    platformTheme = "gnome";
    style = "adwaita-dark";
  };
  nixpkgs.config.allowUnfree = true;
  fonts.fontDir.enable = true;

  environment.systemPackages = with pkgs; [
    vim
    wget
    neovim
    git
    curl
    nil
    nixd
    package-version-server
    rust-analyzer
    rustup
    stdenv.cc
    gnumake
    xdg-utils
    libnotify
    gtop
    uv
    devenv
    wl-clipboard
    ifuse
    libimobiledevice
    elmPackages.elm
    cloudflare-warp
    cloudflared
  ];

  services.cloudflare-warp.enable = false;

  fonts.packages = with pkgs; [
    jetbrains-mono
    # nerd-fonts.jetbrains-mono # patched glyphs for waybar icons
    fira-code
  ];

  fonts.fontconfig = {
    antialias = true;
    hinting.style = "full";
    subpixel.rgba = "rgb";
  };

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
  };

  nix = {
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than-7d";
    };
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  security.sudo = {
    enable = true;
    extraRules = [
      {
        users = [ "anurag" ];
        commands = [
          {
            # `sys-rebuild` fish alias -> sudo nixos-rebuild switch ...
            command = "${pkgs.nixos-rebuild}/bin/nixos-rebuild";
            options = [ "NOPASSWD" ];
          }
          {
            command = "${pkgs.systemd}/bin/reboot";
            options = [ "NOPASSWD" ];
          }
          {
            command = "${pkgs.systemd}/bin/shutdown";
            options = [ "NOPASSWD" ];
          }
          {
            command = "${pkgs.systemd}/bin/poweroff";
            options = [ "NOPASSWD" ];
          }
        ];
      }
    ];
  };

  nixpkgs.config.permittedInsecurePackages = [
    "ventoy-1.1.12"
  ];

  services.keyd = {
    enable = true;
    keyboards = {
      default = {
        ids = [ "0001:0001:09b4e68d" ];
        settings = {
          main = {
            "f23+leftshift+leftmeta" = "layer(meta)";
            "capslock" = "escape";
            "escape" = "capslock";
          };
        };
      };
    };
  };

  system.stateVersion = "26.05";
}
