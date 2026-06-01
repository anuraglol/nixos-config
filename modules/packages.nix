{ pkgs, ... }:

{
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
    opencode
    github-copilot-cli
    hey
    webkitgtk_6_0
    age

    mpv
    vlc
    qbittorrent
    gnome-tweaks
    bibata-cursors
    obs-studio
    ffmpeg

    nodejs
    pnpm
    bun
    go
    gh
    wails
    redis
    python3

    gnomeExtensions.blur-my-shell
    gnomeExtensions.caffeine
    gnomeExtensions.clipboard-indicator
    gnomeExtensions.just-perfection
    gnomeExtensions.system-monitor
  ];
}
