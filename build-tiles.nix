{
  stdenv,
  writeText,
  jq,
  mbutil,
  tilemaker,
  unzip,
  osmium-tool,
}: {
  name,
  src,
  config ? {},
  renumber ? false,
}: let
  tilemaker-config =
    writeText "app-config.json" (builtins.toJSON
      ({settings = {compress = "none";};} // config));
  args =
    if renumber
    then "--compact"
    else "";
  isCompressed =
    (builtins.hasAttr "settings" config)
    && (builtins.hasAttr "compress" config.settings)
    && config.settings.compress != "none";
  # then ''find tiles -name '*.pbf' -exec sh -c 'echo "$1" "$1.gz"' - '{}' +''
in
  stdenv.mkDerivation {
    inherit src;
    name = "${src}-tiles";

    unpackPhase = "true";

    buildInputs = [jq mbutil tilemaker unzip osmium-tool];

    buildPhase = ''
      jq -c '. * input' ${tilemaker}/share/tilemaker/config-openmaptiles.json ${tilemaker-config} > config.json
      ${
        if renumber
        then "osmium renumber -i. -o data.osm.pbf ${src}"
        else "ln -s ${src} data.osm.pbf"
      }
      tilemaker --input data.osm.pbf ${args} --output tiles.mbtiles --config=config.json
      mb-util tiles.mbtiles tiles --image_format=pbf --scheme=xyz
      ${
        if isCompressed
        then ''
          for file in $(find tiles -type f -name '*.pbf'); do
            mv "$file" "$file.gz"
          done
        ''
        else ""
      }
    '';

    installPhase = ''
      mkdir -p $out
      mv tiles $out/
    '';
  }
