{ pkgs, unstable-pkgs, ... }:

{
  home.packages = with pkgs; [
    kitty
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
    killport
    localsend
    eza
    ripgrep

    mpv
    vlc
    qbittorrent
    bibata-cursors

    nautilus
    snapshot
    adwaita-icon-theme
    obs-studio
    ffmpeg
    slack

    nodejs
    pnpm
    bun
    go
    gh
    redis
    python3
    air
    process-compose
    mise
    openssl

    unstable-pkgs.claude-code
    mcp-nixos
  ];
}
