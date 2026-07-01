{ pkgs, unstable-pkgs, ... }:

let
  # qBittorrent (Qt6 Widgets) ignores Sway's fractional scale and renders at 1x,
  # unlike Qt Quick apps (e.g. vicinae) which honour the wayland fractional-scale
  # protocol natively. Force QT_SCALE_FACTOR on this binary only, so it scales
  # correctly regardless of launcher, without polluting the global environment
  # (which would double-scale the apps that already scale themselves).
  qbittorrent-scaled = pkgs.symlinkJoin {
    name = "qbittorrent-scaled";
    paths = [ pkgs.qbittorrent ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/qbittorrent --set QT_SCALE_FACTOR 1.5
    '';
  };
in
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
    qbittorrent-scaled
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
    ruby
    ruby-lsp
    mkcert
    nss

    unstable-pkgs.claude-code
    mcp-nixos
  ];
}
