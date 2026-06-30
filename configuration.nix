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
    ./modules/gnome.nix
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
  i18n.defaultLocale = "en_IN";

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
  };

  services.resolved.enable = false;

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
    ];
    packages = with pkgs; [ ];
    shell = pkgs.fish;
  };

  fileSystems."/home/anurag/Downloads" = {
    device = "/data/Downloads";
    fsType = "ext4";
    options = [
      "bind"
      "nofail"
    ];
  };
  fileSystems."/home/anurag/Documents" = {
    device = "/data/Documents";
    fsType = "ext4";
    options = [
      "bind"
      "nofail"
    ];
  };

  programs.firefox.enable = true;
  programs.dconf.enable = true;
  programs.fish.enable = true;
  programs.yazi.enable = true;

  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    # Add any common missing libraries here if the app crashes later
  ];

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
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
    steam-run
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
