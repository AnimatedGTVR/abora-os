{ config, pkgs, lib, ... }:

let
  isoDerivation = pkgs.runCommand "abora-iso" { buildInputs = [ pkgs.xorriso ]; } ''
    mkdir -p iso-root
    echo "Abora OS" > iso-root/README
    ${pkgs.xorriso}/bin/xorriso -as mkisofs -o $out iso-root
  '';
in
{
  options = {};

  config = {
    system.build.isoImage = isoDerivation;
    system.build.isoName = lib.mkForce ("abora-${config.version or "dev"}-x86_64.iso");
  };
}
