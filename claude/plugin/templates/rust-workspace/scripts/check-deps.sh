#!/usr/bin/env bash
# Enforce the ports and adapters dependency rules for this workspace.
#
# Crates are classified by name suffix: *-core, *-adapters, *-app.
#   core      no workspace dependencies; third-party deps must be listed in
#             scripts/core-allowed-deps.txt (dev-dependencies are exempt)
#   adapters  the only workspace dependency allowed is core
#   app       may depend on core and adapters (the only crate allowed to)
# Any other workspace crate name is an error, so new crates must be classified.
# Requires: cargo, jq.
set -euo pipefail

cd "$(dirname "$0")/.."
allow_file="scripts/core-allowed-deps.txt"

metadata=$(cargo metadata --format-version 1 --no-deps)

# One line per (crate, dependency, kind, is_workspace_member).
rows=$(jq -r '
  (.workspace_members) as $members
  | [.packages[] | select(.id as $id | $members | index($id)) | .name] as $ws
  | .packages[]
  | select(.id as $id | $members | index($id))
  | .name as $crate
  | (.dependencies[] | [$crate, .name, (.kind // "normal"), (.name as $d | $ws | index($d) != null)])
  | @tsv' <<<"$metadata")

crates=$(jq -r '. as $m | .packages[] | select(.id as $id | $m.workspace_members | index($id)) | .name' <<<"$metadata")

allowed=$(grep -v -e '^[[:space:]]*#' -e '^[[:space:]]*$' "$allow_file" || true)

status=0
fail() {
  echo "check-deps: $1" >&2
  status=1
}

role_of() {
  case "$1" in
    *-core) echo core ;;
    *-adapters) echo adapters ;;
    *-app) echo app ;;
    *) echo unknown ;;
  esac
}

for crate in $crates; do
  role=$(role_of "$crate")
  if [[ $role == unknown ]]; then
    fail "crate '$crate' is not named *-core, *-adapters or *-app; classify it in scripts/check-deps.sh"
  fi
done

while IFS=$'\t' read -r crate dep kind is_ws; do
  [[ -z $crate ]] && continue
  role=$(role_of "$crate")
  if [[ $is_ws == true ]]; then
    dep_role=$(role_of "$dep")
    case $role in
      core)
        fail "core crate '$crate' must not depend on workspace crate '$dep' ($kind dependency)"
        ;;
      adapters)
        if [[ $dep_role != core ]]; then
          fail "adapters crate '$crate' may depend on core only, but depends on '$dep' ($kind dependency)"
        fi
        ;;
      app) ;;
      *) ;;
    esac
    if [[ $dep_role == app ]]; then
      fail "crate '$crate' must not depend on app crate '$dep' ($kind dependency)"
    fi
  elif [[ $role == core && $kind != dev ]]; then
    if ! grep -qx -- "$dep" <<<"$allowed"; then
      fail "core crate '$crate' depends on '$dep' ($kind dependency), which is not listed in $allow_file"
    fi
  fi
done <<<"$rows"

# Only app may depend on both core and adapters.
for crate in $crates; do
  [[ $(role_of "$crate") == app ]] && continue
  has_core=$(awk -F'\t' -v c="$crate" '$1==c && $4=="true" && $2 ~ /-core$/' <<<"$rows" | wc -l)
  has_adapters=$(awk -F'\t' -v c="$crate" '$1==c && $4=="true" && $2 ~ /-adapters$/' <<<"$rows" | wc -l)
  if ((has_core > 0 && has_adapters > 0)); then
    fail "crate '$crate' depends on both core and adapters; only the app crate may"
  fi
done

if ((status == 0)); then
  echo "check-deps: ok"
fi
exit "$status"
