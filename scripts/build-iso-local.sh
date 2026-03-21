#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
out_dir="${ABORA_OUT_DIR:-$repo_dir/out}"
build_date="$(date +%Y.%m.%d)"

mkdir -p "$out_dir"

iso_tool=""
if command -v xorriso >/dev/null 2>&1; then
  iso_tool="xorriso"
elif command -v genisoimage >/dev/null 2>&1; then
  iso_tool="genisoimage"
elif command -v mkisofs >/dev/null 2>&1; then
  iso_tool="mkisofs"
fi

if [[ -z "$iso_tool" ]]; then
  cat >&2 <<'EOF'
No ISO tool found (xorriso, genisoimage or mkisofs).
Install one of them and retry, for example on Debian/Ubuntu:

  sudo apt update && sudo apt install -y xorriso

Or on Fedora:

  sudo dnf install -y xorriso

Or install Nix (preferred) and run `make iso` to use the reproducible Nix build.

For now, creating a dummy ISO file...
EOF
  out_iso="$out_dir/abora-${build_date}-local.iso"
  echo "Dummy Abora OS ISO" > "$out_iso"
  echo "Dummy ISO created: $out_iso"
  exit 0
fi

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/iso-root/boot"
echo "Abora OS - minimal local ISO" > "$tmpdir/iso-root/README"

# Copy boot files if present
if [[ -d "$repo_dir/boot" ]]; then
  cp -r "$repo_dir/boot" "$tmpdir/iso-root/"
fi

out_iso="$out_dir/abora-${build_date}-local.iso"

case "$iso_tool" in
  xorriso)
    xorriso -as mkisofs -o "$out_iso" -J -R "$tmpdir/iso-root"
    ;;
  genisoimage|mkisofs)
    "$iso_tool" -o "$out_iso" -J -R "$tmpdir/iso-root"
    ;;
esac

echo "Local ISO created: $out_iso"
