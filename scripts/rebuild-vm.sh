#!/usr/bin/env sh
set -eu

build_device="${ABORA_BUILD_DEVICE:-/dev/vda1}"
build_mount="${ABORA_BUILD_MOUNT:-/mnt/build}"
repo_dir="$build_mount/work/.abora"
cache_dir="$build_mount/pacman-cache"
work_dir="$build_mount/abora-work"
out_dir="$build_mount/abora-out"

if ! command -v mount >/dev/null 2>&1; then
    echo "mount command not found." >&2
    exit 1
fi

mkdir -p "$build_mount"
mountpoint -q "$build_mount" || mount "$build_device" "$build_mount"

mkdir -p "$cache_dir" "$build_mount/work"
mountpoint -q /var/cache/pacman/pkg || mount --bind "$cache_dir" /var/cache/pacman/pkg

if [ ! -d "$repo_dir/.git" ]; then
    git clone https://github.com/AnimatedGTVR/abora-os.git "$repo_dir"
else
    git -C "$repo_dir" pull --ff-only
fi

cd "$repo_dir"
ABORA_WORK_DIR="$work_dir" ABORA_OUT_DIR="$out_dir" ./scripts/build-iso.sh
