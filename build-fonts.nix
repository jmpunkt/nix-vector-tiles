{
  stdenv,
  symlinkJoin,
  build_pbf_glyphs,
  jq,
  writeText,
  fontconfig,
}: {
  name,
  fonts,
}:
stdenv.mkDerivation rec {
  inherit name;

  src = symlinkJoin {
    name = "combined-system-fonts";
    paths = fonts;
  };

  buildInputs = [jq fontconfig];

  buildPhase = ''
    export FONTCONFIG_FILE=${fontconfig.out}/etc/fonts/fonts.conf
    export XDG_CACHE_HOME="$(pwd)/cache"
    mkdir -p "$XDG_CACHE_HOME/fontconfig"

    function build_font() {
      IFS=: read -r ifile name <<< "$0"
      ext=''${ifile##*.}
      mkdir -p tmp-out
      mkdir -p tmp-in
      ln -s "$ifile" tmp-in/
      ${build_pbf_glyphs}/bin/build_pbf_glyphs tmp-in/ tmp-out/
      mv "tmp-out/$(basename $ifile .$ext)" "fonts/$name"
      rm -r tmp-out
      rm -r tmp-in
    }
    export -f build_font
    mkdir -p fonts

    fc-scan ${src} --format "%{file}:%{fullname}\n" | xargs -n1 -d '\n' sh -c 'build_font "$@"'
  '';

  installPhase = ''
    mkdir -p $out/share
    mv fonts $out/share/map-fonts
  '';
}
