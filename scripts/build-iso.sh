#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
out_dir="${ABORA_OUT_DIR:-$repo_dir/out}"
version_id="${ABORA_VERSION_ID:-}"
build_date="$(date +%Y.%m.%d)"

if ! command -v nix >/dev/null 2>&1; then
    echo "nix command not found. Install Nix with flakes support first." >&2
    exit 1
fi

if [[ -z "$version_id" && -f "$repo_dir/VERSION" ]]; then
    version_id="$(tr -d '\n' < "$repo_dir/VERSION")"
fi
version_id="$(printf '%s' "$version_id" | tr -cd '[:alnum:]._-')"
[[ -n "$version_id" ]] || version_id="dev"
case "$version_id" in
    [Vv]*) version_tag="$version_id" ;;
    *) version_tag="v$version_id" ;;
esac

mkdir -p "$out_dir"

export NIX_CONFIG="${NIX_CONFIG:-experimental-features = nix-command flakes}"

nix_target="$repo_dir#packages.x86_64-linux.iso"
echo "Building target: $nix_target"

build_output_path="$(
    nix build "$nix_target" \
        --print-out-paths \
        --print-build-logs \
        --no-link \
        --show-trace | tail -n 1
)"

if [[ -z "$build_output_path" || ! -e "$build_output_path" ]]; then
    echo "Nix build did not return a valid output path." >&2
    exit 1
fi

if [[ -f "$build_output_path" && "$build_output_path" == *.iso ]]; then
    iso_src="$build_output_path"
else
    iso_src="$(find "$build_output_path" -type f -name '*.iso' | head -n 1)"
fi

if [[ -z "${iso_src:-}" || ! -f "$iso_src" ]]; then
    echo "Unable to locate ISO file in Nix build output path: $build_output_path" >&2
    exit 1
fi

target_iso="$out_dir/abora-${build_date}-x86_64-${version_tag}.iso"
cp -f "$iso_src" "$target_iso"

echo "ISO output: $target_iso"
ABORA_OUT_DIR="$out_dir" "$repo_dir/scripts/release-metadata.sh" >/dev/null
