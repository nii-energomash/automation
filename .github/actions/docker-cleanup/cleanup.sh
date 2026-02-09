#!/usr/bin/env bash
set -euo pipefail

#######################################
# Required environment variables
#######################################

: "${GITHUB_REPOSITORY:?GITHUB_REPOSITORY is required (owner/repo)}"
: "${GITHUB_REPOSITORY_OWNER:?GITHUB_REPOSITORY_OWNER is required}"

#######################################
# Inputs with defaults
#######################################

DAYS_OLD="${DAYS_OLD:-0}"
HOURS_OLD="${HOURS_OLD:-1}"
SHOW_ONLY="${SHOW_ONLY:-false}"

#######################################
# Derived values
#######################################

OWNER="$GITHUB_REPOSITORY_OWNER"
REPO="${GITHUB_REPOSITORY#*/}"

#######################################
# Validation
#######################################

if ! [[ "$DAYS_OLD" =~ ^[0-9]+$ ]]; then
  echo "❌ DAYS_OLD must be a non-negative integer"
  exit 1
fi

if ! [[ "$HOURS_OLD" =~ ^([0-9]|1[0-9]|2[0-3])$ ]]; then
  echo "❌ HOURS_OLD must be in range 0–23"
  exit 1
fi

if [[ "$SHOW_ONLY" != "true" && "$SHOW_ONLY" != "false" ]]; then
  echo "❌ SHOW_ONLY must be 'true' or 'false'"
  exit 1
fi

#######################################
# Time calculation
#######################################

CUTOFF_TS="$(date -d "${DAYS_OLD} days ${HOURS_OLD} hours ago" +%s)"

echo "🧹 Docker cleanup"
echo "Owner:        $OWNER"
echo "Repository:   $REPO"
echo "Days old:     $DAYS_OLD"
echo "Hours old:    $HOURS_OLD"
echo "Show only:    $SHOW_ONLY"
echo "Cutoff time:  $(date -d "@$CUTOFF_TS")"
echo

#######################################
# Fetch & process package versions
#######################################

echo "📦 Fetching container versions…"

gh api \
  "/users/${OWNER}/packages/container/${REPO}/versions" \
  --paginate \
  -q "
    .[] |
    select(.metadata.container.tags[]? | startswith(\"sha-\")) |
    select((.updated_at | fromdateiso8601) < ${CUTOFF_TS}) |
    {
      id: .id,
      updated_at: .updated_at,
      tags: .metadata.container.tags
    }
  " |
while read -r version; do
  ID="$(jq -r '.id' <<<"$version")"
  TAGS="$(jq -r '.tags | join(", ")' <<<"$version")"
  UPDATED="$(jq -r '.updated_at' <<<"$version")"

  echo "→ Found candidate:"
  echo "    id:         $ID"
  echo "    tags:       $TAGS"
  echo "    updated_at: $UPDATED"

  if [[ "$SHOW_ONLY" == "true" ]]; then
    echo "    (dry-run, not deleting)"
  else
    echo "    Deleting version $ID"
    gh api \
      --method DELETE \
      "/users/${OWNER}/packages/container/${REPO}/versions/${ID}"
  fi

  echo
done
