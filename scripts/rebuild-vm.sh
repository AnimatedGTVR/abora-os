#!/usr/bin/env sh
set -eu

build_device="${ABORA_BUILD_DEVICE:-/dev/vda1}"
build_mount="${ABORA_BUILD_MOUNT:-/mnt/build}"
repo_dir="$build_mount/work/.abora"
cache_dir="$build_mount/pacman-cache"
work_dir="$build_mount/abora-work"
out_dir="$build_mount/abora-out"
repo_url="${ABORA_REPO_URL:-https://github.com/AnimatedGTVR/abora-os.git}"
pacman_cache_mount="/var/cache/pacman/pkg"
repo_branch="${ABORA_REPO_BRANCH:-main}"

if ! command -v mount >/dev/null 2>&1; then
    echo "mount command not found." >&2
    exit 1
fi

if [ "$(id -u)" -ne 0 ]; then
    echo "Run as root in the Arch build VM." >&2
    exit 1
fi

if [ ! -b "$build_device" ]; then
    echo "Build device not found: $build_device" >&2
    echo "Set ABORA_BUILD_DEVICE or create/partition the disk first." >&2
    exit 1
fi

mkdir -p "$build_mount"
mountpoint -q "$build_mount" || mount "$build_device" "$build_mount"

mkdir -p "$cache_dir" "$build_mount/work"
if mountpoint -q "$pacman_cache_mount"; then
    current_source="$(findmnt -n -o SOURCE --target "$pacman_cache_mount" || true)"
    if [ "$current_source" != "$cache_dir" ]; then
        umount "$pacman_cache_mount"
    fi
fi
mountpoint -q "$pacman_cache_mount" || mount --bind "$cache_dir" "$pacman_cache_mount"

if [ ! -d "$repo_dir/.git" ]; then
    git clone "$repo_url" "$repo_dir"
else
    git -C "$repo_dir" fetch origin "$repo_branch"
    git -C "$repo_dir" checkout "$repo_branch"
    git -C "$repo_dir" pull --ff-only origin "$repo_branch"
fi

cd "$repo_dir"
ABORA_WORK_DIR="$work_dir" ABORA_OUT_DIR="$out_dir" ./scripts/build-iso.sh

echo
echo "Build complete."
echo "ISO output directory: $out_dir"
ls -lah "$out_dir"
