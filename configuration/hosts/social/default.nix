{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix

    ./mastodon.nix
  ];

  boot.supportedFilesystems = [ "vfat" "btrfs" ];
  boot.loader.grup.enable = true;
  boot.loader.grub.version = 2;
  boot.loader.grub.device = "/dev/sda";

  networking.hostName = "social";
  networking.nameservers = [
    "2001:470:20::2"
    "2001:4860:4860::8888"
    "2001:4860:4860::8844"
    "1.1.1.1"
  ];

  systemd.network.networks."40-enp1s0" = {
    name = "enp1s0";
    # TODO addresses = [{ addressConfig.Address = "TODO"; }];
    routes = [{ routeConfig.Gateway = "fe80::1"; }];
  };

  networking.dhcpcd.enable = false;
  networking.useDHCP = false;
  networking.interfaces.enp1s0.useDHCP = true;
  networking.interfaces.enp1s0.tempAddress = "disabled";

  # This value determines the NixOS release with which your system is to be
  # compatible, in order to avoid breaking some software such as database
  # servers. You should change this only after NixOS release notes say you
  # should.
  system.stateVersion = "23.05";
}
