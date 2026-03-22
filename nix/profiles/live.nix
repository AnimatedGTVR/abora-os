{ lib, pkgs, version, ... }:
{
  networking.hostName = "abora";
  system.nixos.tags = [ "abora" "nixos-base" ];
  system.nixos = {
    distroId = "abora";
    distroName = "Abora OS";
    vendorId = "abora";
    vendorName = "Abora OS";
    variant_id = "live";
    variantName = "Live Image";
  };

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.nixPath = [
    "nixpkgs=${pkgs.path}"
    "nixos-config=/etc/nixos/configuration.nix"
  ];

  environment.systemPackages = with pkgs; [
    bashInteractive
    dosfstools
    e2fsprogs
    fastfetch
    git
    curl
    wget
    htop
    iproute2
    kbd
    openssl
    parted
    util-linux
    whois
  ];

  environment.variables = {
    ABORA_VERSION = version;
    ABORA_NIXPKGS_PATH = pkgs.path;
    ABORA_ZONEINFO_PATH = "${pkgs.tzdata}/share/zoneinfo";
  };

  environment.etc."abora/README".text = ''
    Abora OS live image
    Base: Abora OS
  '';

  environment.etc."abora/default-wallpaper.png".source = ../../assets/wallpaper.png;
  environment.etc."abora/title.txt".source = ../../assets/abora-title.txt;
  environment.etc."abora/fastfetch-logo.txt".source = ../../assets/fastfetch-logo.txt;
  environment.etc."abora/fastfetch-config.jsonc".source = ../../assets/fastfetch-config.jsonc;
  environment.etc."abora/plymouth/abora.plymouth".source = ../../assets/plymouth/abora.plymouth;
  environment.etc."abora/plymouth/abora.script".source = ../../assets/plymouth/abora.script;
  environment.etc."abora/nixpkgs".source = pkgs.path;
  environment.etc."abora/lonis/hyprland.conf".source = ../../assets/lonis/hyprland.conf;
  environment.etc."abora/lonis/waybar-config.jsonc".source = ../../assets/lonis/waybar-config.jsonc;
  environment.etc."abora/lonis/waybar-style.css".source = ../../assets/lonis/waybar-style.css;
  environment.etc."abora/lonis/kitty.conf".source = ../../assets/lonis/kitty.conf;
  environment.etc."abora/lonis/rofi.rasi".source = ../../assets/lonis/rofi.rasi;
  environment.etc."abora/lonis/dunstrc".source = ../../assets/lonis/dunstrc;
  environment.etc."xdg/fastfetch/config.jsonc".source = ../../assets/fastfetch-config.jsonc;
  environment.etc."issue".text = ''
    Abora OS
  '';
  environment.etc."issue.net".text = ''
    Abora OS
  '';

  services.xserver.enable = false;
  environment.shellAliases.fastfetch = "fastfetch -c /etc/xdg/fastfetch/config.jsonc";

  environment.etc."abora/boot.sh".source = ../../scripts/abora-boot.sh;
  environment.etc."abora/boot.sh".mode = "0755";
  environment.etc."abora/installer.sh".source = ../../scripts/abora-installer.sh;
  environment.etc."abora/installer.sh".mode = "0755";

  systemd.services."getty@tty1".enable = lib.mkForce false;
  systemd.services.abora-boot = {
    description = "Abora live boot menu";
    wantedBy = [ "multi-user.target" ];
    after = [ "systemd-user-sessions.service" ];
    conflicts = [ "getty@tty1.service" ];
    before = [ "getty@tty1.service" ];
    environment = {
      ABORA_NIXPKGS_PATH = "/etc/abora/nixpkgs";
      ABORA_ZONEINFO_PATH = "${pkgs.tzdata}/share/zoneinfo";
    };

    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.bashInteractive}/bin/bash /etc/abora/boot.sh";
      Restart = "always";
      RestartSec = "0";
      StandardInput = "tty-force";
      StandardOutput = "tty";
      StandardError = "tty";
      TTYPath = "/dev/tty1";
      TTYReset = true;
      TTYVHangup = true;
      TTYVTDisallocate = true;
    };
  };

  isoImage.isoName = lib.mkForce "abora-${version}-x86_64.iso";
  isoImage.splashImage = ../../assets/bootloader/abora-bios.png;
  isoImage.efiSplashImage = ../../assets/bootloader/abora-efi.png;
  isoImage.grubTheme = null;
  isoImage.syslinuxTheme = ''
    MENU TITLE Boot Options
    MENU RESOLUTION 800 600
    MENU ROWS 6
    MENU WIDTH 48
    MENU MARGIN 0
    MENU VSHIFT 11
    MENU HSHIFT 2
    MENU TABMSGROW 23
    MENU CMDLINEROW 24
    MENU HELPMSGROW 26
    MENU HELPMSGENDROW 29
    MENU TIMEOUTROW 28

    MENU COLOR BORDER       30;44      #00000000    #00000000   none
    MENU COLOR SCREEN       37;40      #FF000000    #00000000   none
    MENU COLOR TABMSG       1;37;40    #FFB6C9DF    #00000000   none
    MENU COLOR TIMEOUT      1;37;40    #FFF3FAFF    #00000000   none
    MENU COLOR TIMEOUT_MSG  37;40      #FFB6C9DF    #00000000   none
    MENU COLOR CMDMARK      1;36;40    #FF35C8FF    #00000000   none
    MENU COLOR CMDLINE      37;40      #FFE7F4FF    #00000000   none
    MENU COLOR TITLE        1;36;44    #FF8DF5FF    #00000000   none
    MENU COLOR UNSEL        37;44      #FFEAF5FF    #00000000   none
    MENU COLOR SEL          7;37;40    #FF07101A    #FF35C8FF   std
    MENU COLOR HOTKEY       1;37;40    #FFF3FAFF    #00000000   none
    MENU COLOR HOTSEL       1;37;40    #FF07101A    #FF35C8FF   std
    MENU COLOR SCROLLBAR    30;44      #00000000    #00000000   none
  '';
  isoImage.appendToMenuLabel = " Live";
}
