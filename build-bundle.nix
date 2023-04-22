{runCommand}: {
  host,
  metadataFn,
  styleFn,
}: let
  metadata = metadataFn "${host}/tiles/data/{z}/{x}/{y}.pbf";
  style = styleFn "${host}/tiles/tiles.json" "${host}/fonts" "${host}/sprites/sprite";
in
  runCommand "bundled-tiles" {} ''
    mkdir -p $out/share/www/tiles
    mkdir -p $out/bin
    ln -s ${metadata}/tiles/ $out/share/www/tiles/data
    ln -s ${metadata}/v3.json $out/share/www/tiles/tiles.json
    ln -s ${style}/share/map-style/fonts $out/share/www/fonts
    ln -s ${style}/share/map-style/sprites $out/share/www/sprites
    ln -s ${style}/share/map-style/style.json $out/share/www/style.json
  ''
