{
  lib,
  stdenv,
  jq,
  symlinkJoin,
  moreutils,
  map-sprite-packer,
  optipng,
}: {
  name,
  src,
  overrideJson,
  fonts,
  spriteDirectories ? null,
  spriteWidth ? 600,
  spriteHeight ? 800,
}: let
  fontPath = symlinkJoin {
    name = "combined-style-fonts";
    paths = fonts;
  };
  dirArgs =
    if spriteDirectories != null
    then (builtins.foldl' (a: b: a + b) "" (map (dir: " --svgs ${dir}") spriteDirectories))
    else "";
  shouldPack = spriteDirectories != null;
in
  stdenv.mkDerivation {
    inherit name src;
    buildInputs =
      [fonts jq moreutils optipng]
      ++ (lib.optional shouldPack map-sprite-packer);

    unpackPhase = "true";

    buildPhase = ''
      echo -n '${builtins.toJSON overrideJson}' > override.json
      cp ${src}/style.json ./style.json
      jq '. * input' ./style.json override.json | sponge ./style.json
      mkdir sprites
      ${
        if shouldPack
        then ''
          map-sprite-packer ${dirArgs} --width ${toString spriteWidth} --height ${toString spriteHeight} --output sprites
          optipng -o9 sprites/sprite.png
          optipng -o9 sprites/sprite@2x.png
        ''
        else ""
      }
    '';

    installPhase = ''
      mkdir -p $out/share/map-style
      ${
        if shouldPack
        then "mv sprites $out/share/map-style"
        else "mkdir $out/share/map-style/sprites"
      }
      mv style.json $out/share/map-style/style.json
      ln -s ${fontPath}/share/map-fonts $out/share/map-style/fonts
    '';
  }
