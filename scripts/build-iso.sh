#!/usr/bin/env sh
set -eu

repo_dir="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
profile_dir="$repo_dir/distro/archiso"
work_dir="${ABORA_WORK_DIR:-$repo_dir/work}"
out_dir="${ABORA_OUT_DIR:-$repo_dir/out}"
local_repo_dir="${ABORA_LOCAL_REPO_DIR:-$work_dir/localrepo}"
generated_dir="${ABORA_GENERATED_DIR:-$work_dir/generated}"
generated_pacman_conf="$generated_dir/pacman.conf"
source_wallpaper="$repo_dir/assets/wallpaper.png"
staged_wallpaper_dir="$profile_dir/airootfs/usr/share/wallpapers/Abora"
staged_branding_dir="$profile_dir/airootfs/usr/share/abora"
version_id="${ABORA_VERSION_ID:-}"
build_date="$(date +%Y.%m.%d)"

if ! command -v mkarchiso >/dev/null 2>&1; then
    echo "mkarchiso not found. Install the archiso package first." >&2
    exit 1
fi

if [ "$(id -u)" -ne 0 ]; then
    echo "Run as root so mkarchiso and pacman-key can complete." >&2
    exit 1
fi

if command -v pacman-key >/dev/null 2>&1; then
    if [ ! -s /etc/pacman.d/gnupg/pubring.kbx ]; then
        pacman-key --init
        pacman-key --populate archlinux
    fi
fi

if [ ! -f "$source_wallpaper" ]; then
    echo "Missing default wallpaper: $source_wallpaper" >&2
    exit 1
fi

if [ -z "$version_id" ] && [ -f "$repo_dir/VERSION" ]; then
    version_id="$(tr -d '\n' < "$repo_dir/VERSION")"
fi
version_id="$(printf '%s' "$version_id" | tr -cd '[:alnum:]._-')"
[ -n "$version_id" ] || version_id="dev"
case "$version_id" in
    [Vv]*)
        version_tag="$version_id"
        ;;
    *)
        version_tag="v$version_id"
        ;;
esac

mkdir -p "$work_dir" "$out_dir"
mkdir -p "$staged_wallpaper_dir" "$staged_branding_dir"
mkdir -p "$generated_dir"

cp "$source_wallpaper" "$staged_wallpaper_dir/default.png"
cp "$source_wallpaper" "$staged_branding_dir/default-wallpaper.png"

export ABORA_LOCAL_REPO_DIR="$local_repo_dir"
export ABORA_PACKAGE_WORK_DIR="${ABORA_PACKAGE_WORK_DIR:-$work_dir/pkgbuild}"
export ABORA_PACMAN_CONF="$generated_pacman_conf"

"$repo_dir/scripts/build-local-repo.sh"
sed "s#@ABORA_LOCAL_REPO@#$local_repo_dir#g" "$profile_dir/pacman.conf" > "$generated_pacman_conf"

mkarchiso -v -w "$work_dir" -o "$out_dir" "$profile_dir"

latest_iso="$(find "$out_dir" -maxdepth 1 -type f -name '*.iso' -printf '%T@ %p\n' | sort -nr | head -n 1 | cut -d' ' -f2-)"
if [ -n "$latest_iso" ] && [ -f "$latest_iso" ]; then
    iso_arch="$(basename "$latest_iso" | sed -E 's/^.*-([^-]+)\.iso$/\1/')"
    [ -n "$iso_arch" ] || iso_arch="x86_64"
    target_iso="$out_dir/abora-${build_date}-${iso_arch}-${version_tag}.iso"
    if [ "$latest_iso" != "$target_iso" ]; then
        mv -f "$latest_iso" "$target_iso"
    fi
    echo "ISO output: $target_iso"
fi

"$repo_dir/scripts/release-metadata.sh" >/dev/null
