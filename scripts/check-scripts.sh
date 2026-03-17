#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
cd "$repo_dir"

bash_scripts=(
  "distro/archiso/airootfs/root/customize_airootfs.sh"
  "distro/archiso/airootfs/usr/local/bin/abora-live-extensions"
  "distro/archiso/airootfs/usr/local/bin/abora-live-info"
  "packages/abora-defaults/abora-doctor"
  "packages/abora-defaults/abora-initial-setup"
  "packages/abora-defaults/abora-installer-launcher"
  "packages/abora-defaults/optional-software-install"
  "scripts/build-local-repo.sh"
  "scripts/release-metadata.sh"
)

sh_scripts=(
  "scripts/build-iso.sh"
  "scripts/rebuild-vm.sh"
)

failed=0

pass() {
  printf '[ok]   %s\n' "$1"
}

fail() {
  printf '[fail] %s\n' "$1"
  failed=1
}

check_syntax() {
  local file="$1"
  local shell_name="$2"

  if [[ ! -f "$file" ]]; then
    fail "Missing file: $file"
    return
  fi

  if [[ "$shell_name" == "bash" ]]; then
    if bash -n "$file"; then
      pass "syntax ($shell_name): $file"
    else
      fail "syntax ($shell_name): $file"
    fi
  else
    if sh -n "$file"; then
      pass "syntax ($shell_name): $file"
    else
      fail "syntax ($shell_name): $file"
    fi
  fi
}

check_executable() {
  local file="$1"
  if [[ -x "$file" ]]; then
    pass "executable: $file"
  else
    fail "not executable: $file"
  fi
}

printf 'Abora Script Checks\n'
printf '===================\n'

for file in "${bash_scripts[@]}"; do
  check_syntax "$file" "bash"
done

for file in "${sh_scripts[@]}"; do
  check_syntax "$file" "sh"
done

for file in "${bash_scripts[@]}" "${sh_scripts[@]}"; do
  check_executable "$file"
done

if bash -n "distro/archiso/airootfs/etc/skel/.bash_profile"; then
  pass "syntax (bash): distro/archiso/airootfs/etc/skel/.bash_profile"
else
  fail "syntax (bash): distro/archiso/airootfs/etc/skel/.bash_profile"
fi

live_info_output="$(distro/archiso/airootfs/usr/local/bin/abora-live-info)"
if printf '%s' "$live_info_output" | grep -q "Abora OS live image"; then
  pass "runtime: abora-live-info output"
else
  fail "runtime: abora-live-info output"
fi

if distro/archiso/airootfs/usr/local/bin/abora-live-extensions >/dev/null 2>&1; then
  pass "runtime: abora-live-extensions non-live exit"
else
  fail "runtime: abora-live-extensions non-live exit"
fi

optional_output="$(bash packages/abora-defaults/optional-software-install 2>&1 || true)"
if printf '%s' "$optional_output" | grep -qi "must run as root"; then
  pass "runtime: optional-software-install root guard"
else
  fail "runtime: optional-software-install root guard"
fi

tmp_ok="$(mktemp -d)"
tmp_empty="$(mktemp -d)"
trap 'rm -rf "$tmp_ok" "$tmp_empty"' EXIT

touch "$tmp_ok/test.iso"
if ABORA_OUT_DIR="$tmp_ok" scripts/release-metadata.sh >/dev/null; then
  if [[ -f "$tmp_ok/SHA256SUMS-$(tr -d '\n' < VERSION).txt" ]]; then
    pass "runtime: release-metadata checksum generation"
  else
    fail "runtime: release-metadata checksum generation"
  fi
else
  fail "runtime: release-metadata checksum generation"
fi

empty_output="$(ABORA_OUT_DIR="$tmp_empty" scripts/release-metadata.sh 2>&1 || true)"
if printf '%s' "$empty_output" | grep -q "No ISO files found"; then
  pass "runtime: release-metadata empty-dir guard"
else
  fail "runtime: release-metadata empty-dir guard"
fi

if [[ "$failed" -ne 0 ]]; then
  printf '\nOne or more script checks failed.\n' >&2
  exit 1
fi

printf '\nAll script checks passed.\n'
