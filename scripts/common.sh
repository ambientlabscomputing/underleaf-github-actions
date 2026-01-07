#!/bin/bash
set -euo pipefail

# Validate that at least one server targeting method is provided
validate_targeting() {
  local all_servers="$1"
  local server_ids="$2"
  local tags="$3"

  if [[ "$all_servers" != "true" && -z "$server_ids" && -z "$tags" ]]; then
    echo "::error::At least one server targeting method must be provided: all-servers, server-ids, or tags"
    exit 1
  fi

  # Validate that only one targeting method is used
  local count=0
  [[ "$all_servers" == "true" ]] && ((count++)) || true
  [[ -n "$server_ids" ]] && ((count++)) || true
  [[ -n "$tags" ]] && ((count++)) || true

  if [[ $count -gt 1 ]]; then
    echo "::error::Only one server targeting method can be used at a time"
    exit 1
  fi
}

# Build targeting JSON for API request
build_targeting_json() {
  local all_servers="$1"
  local server_ids="$2"
  local tags="$3"
  local result=""

  if [[ "$all_servers" == "true" ]]; then
    result=$(jq -n '{"all_servers": true}')
  elif [[ -n "$server_ids" ]]; then
    # Convert comma-separated string to JSON array
    result=$(echo "$server_ids" | jq -R 'split(",") | map(select(length > 0)) | {server_ids: .}')
  elif [[ -n "$tags" ]]; then
    # Parse JSON tags string
    result=$(echo "$tags" | jq '{tags: .}')
  fi

  echo "$result"
}
