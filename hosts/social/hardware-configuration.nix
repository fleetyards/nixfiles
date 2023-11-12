{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];

  boot.initrd.availableKernelModules =
    [ "xhci_pci" "virtio_pci" "virtio_scsi" "usbhid" "sr_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/05b0754f-230a-4cb3-b924-df95617c5b97";
    fsType = "btrfs";
    options = [ "compress=zstd" "subvol=root" ];
  };

  fileSystems."/home" = {
    device = "/dev/disk/by-uuid/05b0754f-230a-4cb3-b924-df95617c5b97";
    fsType = "btrfs";
    options = [ "compress=zstd" "subvol=home" ];
  };

  fileSystems."/nix" = {
    device = "/dev/disk/by-uuid/05b0754f-230a-4cb3-b924-df95617c5b97";
    fsType = "btrfs";
    options = [ "compress=zstd" "noatime" "subvol=nix" ];
  };

  fileSystems."/persist" = {
    device = "/dev/disk/by-uuid/05b0754f-230a-4cb3-b924-df95617c5b97";
    fsType = "btrfs";
    options = [ "compress=zstd" "subvol=persist" ];
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/2FA9-F760";
    fsType = "vfat";
  };

  swapDevices =
    [{ device = "/dev/disk/by-uuid/9084693a-393c-4131-9583-21fd5a96b346"; }];

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.enp1s0.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";
}
