{ config, pkgs, lib, ... }:

{
  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking.domain = "fleetyards.net";
  networking.useNetworkd = lib.mkDefault true;
  networking.useDHCP = lib.mkDefault false;
  # TODO: 53 on lo via 20
  systemd.network.networks."20-lo" = {
    name = "lo";
    addresses = [
      { addressConfig.Address = "127.0.0.1/8"; }
      { addressConfig.Address = "127.0.0.53/32"; }
    ];
  };

  # ssh
  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = lib.mkDefault false;
    settings.KbdInteractiveAuthentication = lib.mkDefault false;
    settings.PermitRootLogin = lib.mkDefault "prohibit-password";

    hostKeys = [{
      path = "/persist/openssh/ed25519_key";
      type = "ed25519";
    }];

    extraConfig = ''
      StreamLocalBindUnlink yes
    '';
  };

  sops.age.sshKeyPaths = [ "/persist/openssh/ed25519_key" ];
  sops.defaultSopsFile =
    lib.mkForce (../../secrets + "/${config.networking.hostName}.yaml");

  security.sudo.wheelNeedsPassword = false;

  nftables.enable = true;
  nftables.forwardPolicy = lib.mkDefault "drop";

  services.journald.extraConfig = "SystemMaxUse=2G";

  i18n.defaultLocale = lib.mkDefault "en_US.UTF-8";
  #console.keyMap = lib.mkDefault "neo";
  console.keyMap = lib.mkDefault "de";
  console.font = "Lat2-Terminus16";

  environment.systemPackages = with pkgs; [
    vim
    tmux
    restic
    bash-completion

    rclone
    wireguard-tools
  ];

  environment.variables.EDITOR = "vim";

  users.users.root.openssh.authorizedKeys.keys =
    config.users.users.kloenk.openssh.authorizedKeys.keys;

  systemd.tmpfiles.rules =
    [ "Q /persist 755 root - - -" "Q /persist/data/acme 750 nginx - - -" ];
  services.resolved.dnssec = lib.mkDefault "false";

  services.telegraf.extraConfig.inputs = {
    kernel = { };
    kernel_vmstat = { };
    wireguard = { };
    systemd_units = { unittype = "service,mount,socket,target"; };
  };
  systemd.services.telegraf.serviceConfig.AmbientCapabilities =
    [ "CAP_NET_ADMIN" ];

  documentation.nixos.enable = false;

  security.acme.defaults.email = lib.mkForce "ca@fleetyards.net";
}
