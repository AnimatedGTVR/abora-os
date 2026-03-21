#!/usr/bin/env bash
set -euo pipefail

# Abora Custom Installer - Terminal-based, similar to Calamares

DIALOG=${DIALOG:-dialog}
TITLE="Abora OS Installer"

# Function to show welcome
welcome() {
    $DIALOG --title "$TITLE" --msgbox "Welcome to Abora OS Installer!\n\nThis will guide you through installing Abora OS on your system.\n\nPress OK to continue." 10 50
}

# Select disk
select_disk() {
    disks=$(lsblk -d -n -o NAME,SIZE,MODEL | grep -v loop | awk '{print $1 " " $2 " " $3}')
    DISK=$($DIALOG --title "$TITLE" --menu "Select installation disk:" 15 50 10 $disks 2>&1 >/dev/tty)
    if [ -z "$DISK" ]; then exit 1; fi
    DISK="/dev/$DISK"
}

# Partitioning (simple auto)
partition_disk() {
    $DIALOG --title "$TITLE" --yesno "This will wipe $DISK and create:\n- EFI: 512MB\n- Root: Rest\n\nContinue?" 10 50
    if [ $? -ne 0 ]; then exit 1; fi

    # Partition
    parted $DISK -- mklabel gpt
    parted $DISK -- mkpart ESP fat32 1MiB 512MiB
    parted $DISK -- set 1 esp on
    parted $DISK -- mkpart primary 512MiB 100%

    # Format
    mkfs.fat -F 32 ${DISK}1
    mkfs.ext4 ${DISK}2

    EFI_PART="${DISK}1"
    ROOT_PART="${DISK}2"
}

# Generate config
generate_config() {
    mkdir -p /mnt
    mount $ROOT_PART /mnt
    mkdir -p /mnt/boot
    mount $EFI_PART /mnt/boot

    # Generate hardware config
    nixos-generate-config --root /mnt

    # Basic config
    cat > /mnt/etc/nixos/configuration.nix <<EOF
{ config, pkgs, ... }:
{
  imports = [ ./hardware-configuration.nix ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "abora";
  time.timeZone = "America/New_York";  # TODO: ask user

  users.users.abora = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    initialPassword = "abora";
  };

  environment.systemPackages = with pkgs; [ vim git ];

  services.openssh.enable = true;

  system.stateVersion = "24.11";
}
EOF
}

# Install
install_system() {
    $DIALOG --title "$TITLE" --infobox "Installing NixOS... This may take a while." 5 50
    nixos-install --no-root-passwd
}

# Main
welcome
select_disk
partition_disk
generate_config
install_system

$DIALOG --title "$TITLE" --msgbox "Installation complete! Reboot to start Abora OS." 10 50