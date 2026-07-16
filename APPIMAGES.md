# AppImage Integration — Agent Notes

The system already has AppImage support enabled at the NixOS level (`programs.appimage` + `binfmt` in `configuration.nix`). All you need to do to add a new AppImage is define a custom derivation in `modules/packages.nix` and add it to the `home.packages` list.

## Where to look for examples

- `modules/packages.nix` — search for `httpie-appimage` or `research-appimage`.

## Pattern

Every AppImage integration follows the same boilerplate inside the `let` block of `modules/packages.nix`:

```nix
<name>-appimage =
  let
    pname = "<binary-name>";
    version = "<x.y.z>";
    src = pkgs.fetchurl {
      url = "<direct-download-url>";
      hash = "sha256-<sri-hash>";
      name = "<HumanReadable>-${version}.AppImage";
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

      install -Dm755 ${src} $out/libexec/<pname>/<HumanReadable>.AppImage

      makeWrapper ${pkgs.appimage-run}/bin/appimage-run $out/bin/<pname> \
        --add-flags "$out/libexec/<pname>/<HumanReadable>.AppImage"

      if [ -f ${appimageContents}/<PascalCase>.desktop ]; then
        cp ${appimageContents}/<PascalCase>.desktop $out/share/applications/<PascalCase>.desktop
      else
        cat > $out/share/applications/<PascalCase>.desktop <<EOF
[Desktop Entry]
Name=<Human Readable Name>
Exec=$out/bin/<pname> %U
Terminal=false
Type=Application
Icon=<icon-name>
Categories=<Category>;
EOF
      fi

      sed -i "s|Exec=.*|Exec=$out/bin/<pname> %U|" $out/share/applications/<PascalCase>.desktop
      sed -i "s|TryExec=.*|TryExec=$out/bin/<pname>|" $out/share/applications/<PascalCase>.desktop || true

      if [ -d ${appimageContents}/usr/share/icons ]; then
        cp -r ${appimageContents}/usr/share/icons/* $out/share/icons/
      fi
    '';
```

Then append `<name>-appimage` to the `home.packages` list further down in the same file.

## How to discover metadata from an AppImage

If the AppImage is already on disk (e.g. in `~/Downloads`):

```bash
# 1. List contents to find the .desktop file name and icon paths
7z l /path/to/AppImage | grep -iE '\.desktop|usr/share/icons|icons'

# 2. Extract the desktop entry to read Name, Exec, Icon, Categories, MimeType
7z x -so /path/to/AppImage usr/share/applications/<Name>.desktop

# 3. Compute the sha256 hash for the `hash` field
sha256sum /path/to/AppImage | awk '{print $1}'

# 4. Convert the hex hash to base64 SRI format
echo "<hex>" | xxd -r -p | base64
# Then prefix it with sha256- in the Nix expression.
```

If the AppImage is not on disk yet, download it, run the steps above, then point `fetchurl` to the same URL.

## Post-change validation

```bash
nix flake check
```

If it passes, the AppImage is ready to be deployed with the next rebuild.

## Files that must NOT be edited for AppImage work

- `configuration.nix` — AppImage infra is already there; leave it alone.
- `hardware-configuration.nix` — never touch this file.
- `flake.nix` — no new inputs are needed for standalone AppImages.
