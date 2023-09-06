{
  description = "A rust project";
  inputs = {
    utils.url = "github:numtide/flake-utils";
    build_pbf_glyphs = {
      url = "github:stadiamaps/build_pbf_glyphs";
      flake = false;
    };
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "utils";
    };
    cargo2nix = {
      url = "github:cargo2nix/cargo2nix/release-0.11.0";
      inputs.rust-overlay.follows = "rust-overlay";
    };
    map-sprite-packer = {
      url = "github:jmpunkt/map-sprite-packer";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.rust-overlay.follows = "rust-overlay";
      inputs.cargo2nix.follows = "cargo2nix";
      inputs.utils.follows = "utils";
    };
  };
  outputs = {
    self,
    nixpkgs,
    utils,
    cargo2nix,
    build_pbf_glyphs,
    rust-overlay,
    map-sprite-packer,
  }: let
    buildRustPkgs = pkgs:
      pkgs.rustBuilder.makePackageSet {
        rustVersion = "1.67.1";
        packageFun = import ./Cargo.nix;
        workspaceSrc = build_pbf_glyphs;

        packageOverrides = pkgs:
          pkgs.rustBuilder.overrides.all
          ++ [
            (pkgs.rustBuilder.rustLib.makeOverride {
              name = "freetype-sys";
              overrideAttrs = drv: {
                propagatedBuildInputs =
                  (drv.propagatedBuildInputs or [])
                  ++ [
                    pkgs.freetype
                  ];
              };
            })
            (pkgs.rustBuilder.rustLib.makeOverride {
              name = "pbf_font_tools";
              overrideAttrs = drv: {
                postUnpack = ''
                  # HACK: uses annoying pre-built binaries
                  sed -i 's/&protoc_bin_path().unwrap()/std::path::Path::new("protoc")/g' pbf_font_tools-2.2.0/build.rs
                '';
                propagatedBuildInputs =
                  (drv.propagatedBuildInputs or [])
                  ++ [
                    pkgs.protobuf
                  ];
              };
            })
          ];
      };
    buildForSystem = system: let
      overlays = [self.overlays.default];
      pkgs = import nixpkgs {inherit system overlays;};
      germany = {
        name = "germany";
        continent = "europe";
        date = "230101";
        sha256 = "sha256-G/9YWx4uEY6/yGVr2O5XqL6ivrlpX8Vs6xMlU2nT1DE=";
      };
      hessen = {
        name = "hessen";
        continent = "europe";
        country = "germany";
        date = "230101";
        sha256 = "sha256-sOoPtIEY4TxSm/p0MGc9LGzQtQmIafGH0IWbkby95K8=";
      };
      metadataFnFn = config: tilesUrl:
        pkgs.buildTilesMetadata {
          tileJson = {tiles = [tilesUrl];};
          tiles = pkgs.buildTiles {
            inherit config;
            inherit (hessen) name;
            renumber = true;
            src = pkgs.fetchGeofabrik hessen;
          };
        };
      tiles-demo = style:
        (pkgs.callPackage ./demo.nix {}) {
          bundle = pkgs.buildTilesBundle {
            metadataFn = metadataFnFn {};
            host = "http://127.0.0.1:8081";
            styleFn = style;
          };
        };
      tiles-nginx-bundle = style:
        pkgs.buildTilesBundle {
          metadataFn = metadataFnFn {settings.compress = "gzip";};
          host = "http://127.0.0.1:8080";
          styleFn = style;
        };
      vm-builder = bundle:
        (
          nixpkgs.lib.nixosSystem
          {
            system = "x86_64-linux";
            modules = [
              {nixpkgs.overlays = overlays;}
              "${nixpkgs}/nixos/modules/virtualisation/qemu-vm.nix"
              (import ./demo-nginx.nix {inherit bundle;})
            ];
          }
        )
        .config
        .system
        .build
        .vm;
    in {
      packages = {
        inherit (pkgs) build_pbf_glyphs;
      };
      apps = builtins.foldl' (left: right: left // right) {} (map (
          key: {
            "demo-${key}" = {
              type = "app";
              program = "${tiles-demo pkgs.tilesStyles.${key}}/bin/demo";
            };
            "demo-nginx-${key}" = {
              type = "app";
              program = "${vm-builder (tiles-nginx-bundle pkgs.tilesStyles.${key})}/bin/run-nixos-vm";
            };
          }
        ) [
          "maptiler-basic-gl-style"
          "osm-bright-gl-style"
          "positron-gl-style"
          "dark-matter-gl-style"
          "maptiler-terrain-gl-style"
          "maptiler-3d-gl-style"
          "fiord-color-gl-style"
          "maptiler-toner-gl-style"
          "osm-liberty"
        ]);
    };
  in
    (utils.lib.eachDefaultSystem buildForSystem)
    // {
      overlays = let
        standalone = final: prev: {
          build_pbf_glyphs = (((buildRustPkgs prev).workspace).build_pbf_glyphs {}).bin;
          fetchGeofabrik = prev.callPackage ./fetch-geofabrik.nix {};
          buildTiles = prev.callPackage ./build-tiles.nix {};
          buildTilesBundle = prev.callPackage ./build-bundle.nix {};
          buildTilesFonts = prev.callPackage ./build-fonts.nix {};
          buildTilesStyle = prev.callPackage ./build-style.nix {};
          buildTilesMetadata = prev.callPackage ./build-metadata.nix {};
          tilesStyles = final.callPackage ./styles.nix {};
        };
      in {
        inherit standalone;
        default = nixpkgs.lib.composeManyExtensions [
          cargo2nix.overlays.default
          map-sprite-packer.overlays.default
          standalone
        ];
      };
    };
}
