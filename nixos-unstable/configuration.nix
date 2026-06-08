{ config, pkgs, ... }:
{
  imports = [ ./hardware-configuration.nix ];

  boot.loader.grub.devices = [ "/dev/vda" ];

  networking.hostName = "pihole";
  networking.useDHCP = false;
  networking.interfaces.enp1s0.ipv4.addresses = [{
    address = "192.168.122.59";
    prefixLength = 24;
  }];
  networking.defaultGateway = "192.168.122.1";
  networking.nameservers = [ "1.1.1.1" ];

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 53 80 443 ];
    allowedUDPPorts = [ 53 ];
  };

  services.resolved.settings.Resolve.DNSStubListener = "no";

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  users.users.admin = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 *** ***@protonmail.com"
    ];
  };

  security.sudo.wheelNeedsPassword = false;

  services.pihole-ftl = {
    enable = true;
    settings = {
      dns.upstreams = [ "9.9.9.9" "1.1.1.1" ];
      #webserver.api.password = "***";
      misc.readOnly = true;
      webserver.api.pwhash = "$BALLOON-SHA256$***";
    };
    lists = [{
      url = "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts";
      type = "block";
      enabled = true;
      description = "StevenBlack unified";
    }];
  };

  services.pihole-web = {
    enable = true;
    ports = [ "443s" ];
  };

  environment.systemPackages = with pkgs; [
  neovim
  bind
  ];

  system.stateVersion = "25.05";
}

