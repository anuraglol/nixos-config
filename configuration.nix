{ config, pkgs, ... }:

let
  unstable = import <nixpkgs-unstable> { config = config.nixpkgs.config; };
in
{
  imports =
    [
      ./hardware-configuration.nix
    ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking.hostName = "nixos";

  networking.networkmanager.enable = true;

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

  services.xserver.enable = true;

  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  services.printing.enable = true;

  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

services.udev.extraRules = ''
  SUBSYSTEM=="pci", DRIVER=="xhci_hcd", ATTR{power/wakeup}="disabled"
'';

systemd.services.disable-gpp-wakeup = {
path = [ pkgs.gnugrep pkgs.coreutils ];
  description = "Disable GPP/GP PCIe bridge wakeup sources";
  wantedBy = [ "multi-user.target" ];
  after = [ "systemd-udevd.service" ];
  serviceConfig = {
    Type = "oneshot";
    RemainAfterExit = true;
    ExecStart = let
      script = pkgs.writeShellScript "disable-gpp-wakeup" ''
        for dev in GPP1 GPP6 GPP7 GP19; do
          if grep -q "^''${dev}.*enabled" /proc/acpi/wakeup; then
            echo "$dev" > /proc/acpi/wakeup
            echo "disabled $dev"
          fi
        done
      '';
    in "${script}";
  };
};

  services.flatpak.enable = true;

  users.users.anurag = {
    isNormalUser = true;
    description = "anurag";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [];
    shell = pkgs.fish;
  };

  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      mesa
      vulkan-tools
      vulkan-loader
      vulkan-validation-layers
      libva
      libva-utils
      mesa.opencl
    ];
  };

  programs.firefox.enable = true;
  programs.dconf.enable = true;
  programs.fish.enable = true;

  nixpkgs.config.allowUnfree = true;
  fonts.fontDir.enable = true;

  hardware.bluetooth = {
  enable = true;
  powerOnBoot = true;
};

  environment.systemPackages = with pkgs; [
    vim
    wget
    neovim
    git
    curl
    kitty
    fzf
    fastfetch
    pnpm
    wl-clipboard
    go
    cloudflare-warp
    qbittorrent
    mpv
    vlc
    fish
    htop
    bibata-cursors
    gnome-tweaks
    jetbrains-mono
    bun
    nodejs
    gh
    zoxide
    unzip
    p7zip
    ghostty
    tmux
    unstable.zed-editor
    nil
  ];

  environment.variables = {
    AMD_VULKAN_ICD = "RADV";
  };

  fonts.packages = with pkgs; [
    jetbrains-mono
  ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  system.stateVersion = "25.11";
}
