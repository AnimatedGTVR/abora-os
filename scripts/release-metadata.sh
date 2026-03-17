#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
version="$(tr -d '\n' < "$repo_dir/VERSION")"
out_dir="${ABORA_OUT_DIR:-$repo_dir/out}"

mkdir -p "$out_dir"

(
    cd "$out_dir"
    shopt -s nullglob
    iso_files=(./*.iso)
    if [ "${#iso_files[@]}" -eq 0 ]; then
        echo "No ISO files found in: $out_dir" >&2
        exit 1
    fi
    sha256sum "${iso_files[@]}" > "SHA256SUMS-${version}.txt"
)

printf '%s\n' "$version"
