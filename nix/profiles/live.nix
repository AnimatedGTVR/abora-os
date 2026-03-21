{ lib, pkgs, version, ... }:
{
  imports = [
    ../modules/live-extensions.nix
  ];

  networking.hostName = "abora";
  system.nixos.tags = [ "abora" "nixos-base" ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  environment.systemPackages = with pkgs; [
    fastfetch
    git
    curl
    wget
    htop
    dialog  # For TUI installer
  ];

  environment.variables = {
    ABORA_VERSION = version;
  };

  environment.etc."abora/README".text = ''
    Abora OS live image
    Base: NixOS
  '';

  environment.etc."abora/default-wallpaper.png".source = ../../assets/wallpaper.png;

  # Boot to console, not desktop
  services.xserver.enable = false;

  # Auto-login to installer user
  services.getty.autologinUser = "installer";

  users.users.installer = {
    isNormalUser = true;
    password = "";  # No password for auto-login
    extraGroups = [ "wheel" ];
  };

  # Run installer on boot
  systemd.services.abora-installer = {
    description = "Abora Custom Installer";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    serviceConfig = {
      Type = "oneshot";
      User = "installer";
      ExecStart = "${pkgs.bash}/bin/bash /etc/abora/installer.sh";
      RemainAfterExit = true;
    };
  };

  # Copy installer script
  environment.etc."abora/installer.sh".source = ../../scripts/abora-installer.sh;
  environment.etc."abora/installer.sh".mode = "0755";

  isoImage.isoName = lib.mkForce "abora-${version}-x86_64.iso";
  isoImage.appendToMenuLabel = " Installer";
}
