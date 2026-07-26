{
  config,
  pkgs,
  unstable-pkgs,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
    ./modules/hardware.nix
    ./modules/sway.nix
    ./modules/greeter.nix
  ];

  boot.loader = {
    systemd-boot.enable = true;
    efi = {
      canTouchEfiVariables = true;
    };
    timeout = 1;
  };

  boot.kernelParams = [
    "amdgpu.dcdebugmask=0x10"
    "nvme_core.default_ps_max_latency_us=0"
  ];

  hardware.amdgpu.initrd.enable = true;

  networking.hostName = "neko";

  time.timeZone = "Asia/Kolkata";
  # glibc-locales does not include en_IN.UTF-8 by default, so use a
  # supported UTF-8 locale as the default and keep Indian formats via
  # the individual LC_* variables.
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

  services.printing.enable = false;
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  services.power-profiles-daemon.enable = true;
  services.upower.enable = true;
  services.tailscale = {
    enable = true;
  };

  services.usbmuxd.enable = true;

  services.flatpak.enable = true;
  networking = {
    nameservers = [
      "127.0.0.1"
      "::1"
    ];
    networkmanager = {
      enable = true;
      dns = "none";
    };
    extraHosts = ''
      127.0.0.1 local.app.beanstalk.fi
    '';
  };

  services.resolved.enable = false;
  virtualisation.docker = {
    enable = true;
  };

  services.stubby = {
    enable = true;
    settings = pkgs.stubby.passthru.settingsExample // {
      upstream_recursive_servers = [
        {
          address_data = "1.1.1.1";
          tls_auth_name = "cloudflare-dns.com";
        }
        {
          address_data = "1.0.0.1";
          tls_auth_name = "cloudflare-dns.com";
        }
        {
          address_data = "8.8.8.8";
          tls_auth_name = "dns.google";
        }
        {
          address_data = "8.8.4.4";
          tls_auth_name = "dns.google";
        }
      ];
    };
  };

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 53317 ];
    allowedUDPPorts = [ 53317 ];
  };

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
    ];
    packages = with pkgs; [ ];
    shell = pkgs.fish;
  };

  programs.firefox.enable = true;
  programs.dconf.enable = true;
  programs.fish.enable = true;
  programs.yazi.enable = true;

  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    # Add any common missing libraries here if the app crashes later
  ];
  programs.appimage = {
    enable = true;
    binfmt = true;
  };

  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
      pkgs.xdg-desktop-portal-gnome
    ];
    # Route the file picker to the GNOME backend (the pretty GTK4/Nautilus one);
    # let gtk handle everything else. wlr (from sway.nix) keeps screencast/screenshot.
    config.common."org.freedesktop.impl.portal.FileChooser" = [ "gnome" ];
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
    stdenv.cc
    gnumake
    xdg-utils
    libnotify
    gtop
    cloudflare-warp
    uv
    devenv
    wl-clipboard
    ifuse
  ];

  fonts.packages = with pkgs; [
    jetbrains-mono
    nerd-fonts.jetbrains-mono # patched glyphs for waybar icons
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
