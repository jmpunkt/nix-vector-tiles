{bundle}: {
  config,
  lib,
  pkgs,
  ...
}: {
  # personal preference
  console = {
    font = "Lat2-Terminus16";
    keyMap = "de";
  };

  # enable easy login to root via console
  users = {
    mutableUsers = false;
    users.root = {
      password = "";
      isSystemUser = true;
    };
  };
  networking.firewall.enable = lib.mkForce false;

  # map port 80 to 8080
  virtualisation = {
    qemu = {
      networkingOptions = [
        # We need to re-define our usermode network driver
        # since we are overriding the default value.
        "-net nic,netdev=user.1,model=virtio"
        # Than we can use qemu's hostfwd option to forward ports.
        "-netdev user,id=user.1,hostfwd=tcp::8080-:80"
      ];
    };
  };

  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    recommendedOptimisation = true;
    recommendedGzipSettings = true;
    recommendedBrotliSettings = true;
    virtualHosts."localhost" = {
      enableACME = false;
      forceSSL = false;
      root = "${bundle}/share/www";
      extraConfig = ''
        location / {
            try_files $uri /index.html;

             location /tiles/data/ {
              gunzip on;
              gzip_static on;
              gzip_proxied expired no-cache no-store private auth;
            }
        }
        location =/index.html {
            alias ${./demo.html};
        }
      '';
    };
  };
}
