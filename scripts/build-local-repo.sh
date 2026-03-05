#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
packages_dir="${ABORA_PACKAGES_DIR:-$repo_dir/packages}"
local_repo_dir="${ABORA_LOCAL_REPO_DIR:-$repo_dir/work/localrepo}"
package_work_dir="${ABORA_PACKAGE_WORK_DIR:-$repo_dir/work/pkgbuild}"
builder_user="${ABORA_PACKAGE_BUILDER:-aborabuild}"
builder_home="${ABORA_PACKAGE_BUILDER_HOME:-$package_work_dir/home}"

if ! command -v makepkg >/dev/null 2>&1; then
    echo "makepkg not found. Install base-devel on the build host." >&2
    exit 1
fi

if ! command -v repo-add >/dev/null 2>&1; then
    echo "repo-add not found. Install pacman on the build host." >&2
    exit 1
fi

if ! id "$builder_user" >/dev/null 2>&1; then
    useradd --system --create-home --home-dir "$builder_home" --shell /bin/bash "$builder_user"
fi

mkdir -p "$builder_home"
mkdir -p "$local_repo_dir" "$package_work_dir"
rm -f "$local_repo_dir"/*.pkg.tar.* "$local_repo_dir"/abora-local.db* "$local_repo_dir"/abora-local.files*

for pkg_dir in "$packages_dir"/*; do
    [ -d "$pkg_dir" ] || continue

    pkg_name="$(basename "$pkg_dir")"
    build_dir="$package_work_dir/$pkg_name"
    srcdest="$package_work_dir/src"

    rm -rf "$build_dir"
    mkdir -p "$build_dir" "$srcdest"
    cp -a "$pkg_dir/." "$build_dir/"

    chown -R "$builder_user:$builder_user" "$build_dir" "$srcdest" "$local_repo_dir" "$builder_home"

    su -s /bin/bash "$builder_user" -c "
      cd '$build_dir'
      export HOME='$builder_home'
      export PKGDEST='$local_repo_dir'
      export SRCDEST='$srcdest'
      makepkg --clean --cleanbuild --force --nodeps --noconfirm
    "
done

repo-add "$local_repo_dir/abora-local.db.tar.gz" "$local_repo_dir"/*.pkg.tar.*
