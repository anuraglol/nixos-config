{ pkgs, unstable-pkgs, ... }:

{
  home.packages = with pkgs; [
    kitty
    ghostty
    fastfetch
    fzf
    zoxide
    tmux
    htop
    unzip
    p7zip
    opencode
    github-copilot-cli
    hey
    webkitgtk_6_0
    age
    quickshell
    nh
    impression
    gpu-screen-recorder

    mpv
    vlc
    qbittorrent
    gnome-tweaks
    bibata-cursors
    obs-studio
    ffmpeg
    slack

    nodejs
    pnpm
    bun
    go
    gh
    wails
    redis
    python3
    air
    process-compose
    mise
    openssl

    gnomeExtensions.blur-my-shell
    gnomeExtensions.caffeine
    gnomeExtensions.clipboard-indicator
    gnomeExtensions.just-perfection
    gnomeExtensions.system-monitor
    gnomeExtensions.vicinae

    unstable-pkgs.claude-code
  ];
}
