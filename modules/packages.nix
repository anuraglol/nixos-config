{
  pkgs,
  core-pkgs,
  sidra,
  ...
}:

let
  qbittorrent-scaled = pkgs.symlinkJoin {
    name = "qbittorrent-scaled";
    paths = [ pkgs.qbittorrent ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/qbittorrent --set QT_SCALE_FACTOR 1.25
    '';
  };

  helium-scaled = pkgs.symlinkJoin {
    name = "helium-scaled";
    paths = [ pkgs.helium ];
    buildInputs = [ pkgs.makeWrapper ];

    postBuild = ''
      wrapProgram $out/bin/helium \
        --add-flags "--force-device-scale-factor=1.05"
    '';
  };

  httpie-appimage =
    let
      pname = "httpie";
      version = "2025.2.0";
      src = pkgs.fetchurl {
        url = "https://github.com/httpie/desktop/releases/download/v${version}/HTTPie-${version}.AppImage";
        hash = "sha256-qFDiFXQbYAhweQhgYfZW/lUMtmw09tqT9t/GPJRtZU8=";
        name = "HTTPie-${version}.AppImage";
      };
      appimageContents = pkgs.appimageTools.extract {
        inherit pname version src;
      };
    in
    pkgs.runCommand "${pname}-${version}"
      {
        nativeBuildInputs = [ pkgs.makeWrapper ];
        meta.mainProgram = pname;
      }
      ''
              mkdir -p $out/bin $out/share/applications $out/share/icons

              # Install the AppImage itself into the derivation
              install -Dm755 ${src} $out/libexec/httpie/HTTPie.AppImage

              # Create a wrapper script so `httpie` launches via appimage-run
              makeWrapper ${pkgs.appimage-run}/bin/appimage-run $out/bin/httpie \
                --add-flags "$out/libexec/httpie/HTTPie.AppImage"

              # Re-use the desktop entry shipped inside the AppImage
              if [ -f ${appimageContents}/httpie.desktop ]; then
                cp ${appimageContents}/httpie.desktop $out/share/applications/httpie.desktop
              else
                cat > $out/share/applications/httpie.desktop <<EOF
        [Desktop Entry]
        Name=HTTPie
        Exec=$out/bin/httpie %U
        Terminal=false
        Type=Application
        Icon=httpie
        Categories=Development;
        EOF
              fi

              # Patch Exec so it points to our wrapper
              sed -i "s|Exec=.*|Exec=$out/bin/httpie %U|" $out/share/applications/httpie.desktop
              sed -i "s|TryExec=.*|TryExec=$out/bin/httpie|" $out/share/applications/httpie.desktop || true

              # Install icons that ship inside the AppImage
              if [ -d ${appimageContents}/usr/share/icons ]; then
                cp -r ${appimageContents}/usr/share/icons/* $out/share/icons/
              fi
      '';

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
    github-copilot-cli
    hey
    webkitgtk_6_0
    age
    quickshell
    nh
    impression
    gimp
    gpu-screen-recorder
    killport
    localsend
    eza
    ripgrep
    docker
    btop

    mpv
    vlc
    qbittorrent-scaled
    bibata-cursors
    chromium
    helium-scaled
    obsidian

    nautilus
    snapshot
    loupe
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
    awscli
    fff
    ocaml
    ollama
    llama-cpp
    zig
    caddy
    clang
    rustc
    rustfmt
    cargo
    SDL2
    llvm
    pkg-config
    alsa-lib
    sqlite
    dig
    github-copilot-cli
    helix
    gnome-boxes
    libreoffice

    pkgs.claude-code
    httpie-appimage

    rust-analyzer
    gopls
    typescript
    typescript-language-server
    svelte-language-server

    lldb
    delve
    sidra.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];
}
