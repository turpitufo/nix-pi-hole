{
  config, pkgs, ...
}:

{
  imports = [ ./hardware-configuration.nix ];

  networking = {
    hostName = "Hal";
    networkmanager.enable = true;
    networkmanager.insertNameservers = [ "192.168.0.***" ];
  };

  networking.firewall = {
    allowedTCPPorts = [ 53 80 443 ];
    allowedUDPPorts = [ 53 67 ];
  };

  services.resolved = {
    enable = true;
    settings.Resolve.DNSStubListener = "no";
  };

  services.pihole-ftl = {
    enable = true;
    settings = {
      dns.upstreams = [ "9.9.9.9" "1.1.1.1" ];
      misc.readOnly = true;
      webserver.api.pwhash = "$BALLOON-SHA256$v=1$s=1024,t=32$ZHSvhQetnarsiZeoe/2SuA==$dtzluoZyYJ58oh/****";
      dhcp = {
        active = true;
        start = "192.168.0.50";
        end = "192.168.0.250";
        router = "192.168.0.1";
        domain = "local";
      };
    };
    lists = [
      { url = "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts"; type = "block"; enabled = true; description = "StevenBlack unified"; }
      { url = "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/adblock/pro.txt"; type = "block"; enabled = true; description = "Hagezi Pro"; }
      { url = "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/adblock/tif.txt"; type = "block"; enabled = true; description = "Hagezi Threat Intelligence"; }
      { url = "https://big.oisd.nl/"; type = "block"; enabled = true; description = "OISD Big"; }
      { url = "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/adblock/social.txt"; type = "block"; enabled = true; description = "Hagezi Social"; }
    ];
  };

  services.pihole-web = {
    enable = true;
    ports = [ "443s" ];
  };

  system.stateVersion = "25.05";
}
