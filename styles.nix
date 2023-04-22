{
  buildTilesFonts,
  buildTilesStyle,
  fetchFromGitHub,
  noto-fonts,
  roboto,
  moreutils,
}: let
  noto-tiles = buildTilesFonts {
    name = "noto";
    fonts = [noto-fonts];
  };
  roboto-tiles =
    (buildTilesFonts {
      name = "roboto";
      fonts = [roboto];
    })
    .overrideAttrs (old: {
      installPhase =
        (old.installPhase or "")
        + ''
          mv $out/share/map-fonts/Roboto "$out/share/map-fonts/Roboto Regular"
        '';
    });
  removeMetropolisFont = drv:
    drv.overrideAttrs (old: {
      buildInputs = (old.buildInputs or []) ++ [moreutils];
      buildPhase =
        (old.buildPhase or "")
        + ''
          jq '(.layers | .[] | .layout | ."text-font") |= if (. == null)  then empty else map(select(contains("Metropolis") | not)) end' style.json | sponge style.json
        '';
    });
in {
  # all styles should have the form of <absolute path of tileJson
  # file> and <absolute path to fonts until {fontstack}> as function
  # arguments.
  maptiler-basic-gl-style = tilesJson: fontPath: spritePath:
    buildTilesStyle
    rec {
      overrideJson = {
        sources.openmaptiles.url = tilesJson;
        glyphs = "${fontPath}/{fontstack}/{range}.pbf";
      };
      name = "maptiler-basic-gl-style";
      fonts = [noto-tiles];
      src = fetchFromGitHub {
        owner = "openmaptiles";
        repo = name;
        rev = "tags/v1.9";
        sha256 = "sha256-LRzk0/r2bkAl4qxGNzhRs7QojsNmBWdUUD/d4aqzWu4=";
      };
    };
  osm-bright-gl-style = tilesJson: fontPath: spritePath:
    buildTilesStyle
    rec {
      spriteDirectories = ["${src}/icons"];
      overrideJson = {
        sources.openmaptiles.url = tilesJson;
        sprite = spritePath;
        glyphs = "${fontPath}/{fontstack}/{range}.pbf";
      };
      name = "osm-bright-gl-style";
      fonts = [noto-tiles];
      src = fetchFromGitHub {
        owner = "openmaptiles";
        repo = name;
        rev = "tags/v1.9";
        sha256 = "sha256-X1ueE6cVTEA1D9ctjHMqWJQhdM37RZxciCBQUaQyG64=";
      };
    };
  positron-gl-style = tilesJson: fontPath: spritePath:
    removeMetropolisFont
    (buildTilesStyle
      rec {
        overrideJson = {
          sources.openmaptiles.url = tilesJson;
          glyphs = "${fontPath}/{fontstack}/{range}.pbf";
        };
        name = "positron-gl-style";
        fonts = [noto-tiles]; # missing Metropolis
        src = fetchFromGitHub {
          owner = "openmaptiles";
          repo = name;
          rev = "tags/v1.8";
          sha256 = "sha256-TV3a9in+q5WYS90GhIs1I8JNSUPJy67CmiPdIK1ZO0o=";
        };
      });
  dark-matter-gl-style = tilesJson: fontPath: spritePath:
    removeMetropolisFont
    (buildTilesStyle
      rec {
        spriteDirectories = ["${src}/icons"];
        overrideJson = {
          sources.openmaptiles.url = tilesJson;
          sprite = spritePath;
          glyphs = "${fontPath}/{fontstack}/{range}.pbf";
        };
        name = "dark-matter-gl-style";
        fonts = [noto-tiles]; # missing Metropolis
        src = fetchFromGitHub {
          owner = "openmaptiles";
          repo = name;
          rev = "tags/v1.8";
          sha256 = "sha256-+xT/QbU+VcTepD4A05sA5c97xAgXOwcIbAKPaifKYxQ=";
        };
      });
  maptiler-terrain-gl-style = tilesJson: fontPath: spritePath:
    buildTilesStyle
    rec {
      overrideJson = {
        sources.openmaptiles.url = tilesJson;
        glyphs = "${fontPath}/{fontstack}/{range}.pbf";
      };
      name = "maptiler-terrain-gl-style";
      fonts = [noto-tiles];
      src = fetchFromGitHub {
        owner = "openmaptiles";
        repo = name;
        rev = "tags/v1.7";
        sha256 = "sha256-xXe596/b7+gF6bEW00hEppDLho53ivlsRGHfHd5Vu1E=";
      };
    };
  maptiler-3d-gl-style = tilesJson: fontPath: spritePath:
    buildTilesStyle
    rec {
      overrideJson = {
        sources.openmaptiles.url = tilesJson;
        glyphs = "${fontPath}/{fontstack}/{range}.pbf";
      };
      name = "maptiler-3d-gl-style";
      fonts = [noto-tiles];
      src = fetchFromGitHub {
        owner = "openmaptiles";
        repo = name;
        rev = "9fc742213ec52f0489efb909bfc79eee0015b810";
        sha256 = "sha256-vZSAUMEYmg0/qzq8JiNQZsN8dUNM6+71mPr27m8nDHc=";
      };
    };
  fiord-color-gl-style = tilesJson: fontPath: spritePath:
    removeMetropolisFont
    (buildTilesStyle
      rec {
        overrideJson = {
          sources.openmaptiles.url = tilesJson;
          glyphs = "${fontPath}/{fontstack}/{range}.pbf";
        };
        name = "fiord-color-gl-style";
        fonts = [noto-tiles];
        src = fetchFromGitHub {
          owner = "openmaptiles";
          repo = name;
          rev = "tags/v1.5";
          sha256 = "sha256-Vc+pO8NfMFe6j9P7/5RkS4G6yHTG2jOvFc4Iy0jaAck=";
        };
      });
  maptiler-toner-gl-style = tilesJson: fontPath: spritePath:
    buildTilesStyle
    rec {
      overrideJson = {
        sources.openmaptiles.url = tilesJson;
        glyphs = "${fontPath}/{fontstack}/{range}.pbf";
      };
      name = "maptiler-toner-gl-style";
      fonts = [noto-tiles];
      src = fetchFromGitHub {
        owner = "openmaptiles";
        repo = name;
        rev = "339e5b74c918e8b2787bb4910282d61a5de1d5ee";
        sha256 = "sha256-z3s1fPxEpjXzxPUg4tkPqdp8zvnrK7+L3QOa8uhF8wE=";
      };
    };
  osm-liberty = tilesJson: fontPath: spritePath: (buildTilesStyle
    rec {
      spriteDirectories = ["${src}/svgs/svgs_not_in_iconset" "${src}/svgs/svgs_iconset"];
      overrideJson = {
        sources.openmaptiles.url = tilesJson;
        sprite = spritePath;
        glyphs = "${fontPath}/{fontstack}/{range}.pbf";
      };
      name = "osm-liberty";
      fonts = [roboto-tiles];
      src = fetchFromGitHub {
        owner = "maputnik";
        repo = name;
        rev = "539d0525421eb5be901ede630c49947dfe5a343f";
        sha256 = "sha256-njf1hqIRfoZUnHr3kUGlfCvVBZkIM9ZM6lR8WroOR9s=";
      };
    });
}
