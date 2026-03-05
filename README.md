# Abora OS

Abora OS is an Arch Linux based distribution project built around KDE Plasma. The current work in this repository is focused on the distro track: an `archiso` profile, package selection, branding, and the path toward a bootable live ISO.

## Repository layout

- `assets/`: branding and visual assets
- `distro/archiso/`: first Abora OS `archiso` profile
- `scripts/build-iso.sh`: wrapper around `mkarchiso`
- `scripts/rebuild-vm.sh`: one-command rebuild flow for the Arch build VM
- `docs/roadmap.md`: short-term distro roadmap

## Current Abora OS direction

- base distro: Arch Linux
- image builder: `archiso`
- desktop target: KDE Plasma
- display stack: Plasma on Wayland by default
- initial live environment strategy: ship a usable Plasma-based image first
- package policy: keep the default system lean, graphical, and developer-friendly

## What exists now

- an `archiso` profile with Abora branding files
- a first-pass Plasma-based package manifest for a live image
- a build script that calls `mkarchiso`
- planning docs for the next distro milestones

## Build prerequisites

For the ISO:

- Arch Linux host or compatible environment
- `archiso`
- root privileges for `mkarchiso`

## Local commands

Build the ISO:

```sh
./scripts/build-iso.sh
```

In the Arch build VM, use the one-command rebuild helper:

```sh
./scripts/rebuild-vm.sh
```

`rebuild-vm.sh` handles build-disk mount, pacman cache bind-mount, repo update, and ISO build in one run.
