{
  symlinkJoin,
  writeShellScriptBin,
  runCommand,
  miniserve,
  buildNpmPackage,
  fetchFromGitHub,
  callPackage,
}: {bundle}: let
  demo-html = runCommand "demo-tiles" {} ''
    mkdir -p $out/share/www/
    cp ${./demo.html} $out/share/www/index.html
  '';
  serve = symlinkJoin {
    name = "combined-demo";
    paths = [demo-html bundle];
  };
in
  writeShellScriptBin "demo" ''
    ${miniserve}/bin/miniserve -p 8081 ${serve}/share/www
  ''
