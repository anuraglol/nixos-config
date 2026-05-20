{ config, pkgs, ... }:
{
  home.username = "anurag";
  home.homeDirectory = "/home/anurag";
  home.stateVersion = "25.11";

  programs.home-manager.enable = true;

  # Your personal developer tools and applications (moved out of system context)
  home.packages = with pkgs; [
    kitty
    ghostty
    fastfetch
    fzf
    zoxide
    tmux
    wl-clipboard
    htop
    unzip
    p7zip

    # Media & Customization utilities
    mpv
    vlc
    qbittorrent
    gnome-tweaks
    bibata-cursors

    # Runtimes & Version Control
    nodejs
    pnpm
    bun
    go
    gh
  ];

  # Natively manage user configurations for your Fish shell
  programs.fish = {
    enable = true;
  };
}
