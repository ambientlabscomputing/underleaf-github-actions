#!/bin/bash
set -euo pipefail

# Validate that at least one server targeting method is provided
validate_targeting() {
  local all_servers="$1"
  local server_ids="$2"
  local tags="$3"

  echo "::debug::Validating targeting - all_servers: $all_servers, server_ids: $server_ids, tags: $tags"

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
    echo "::error::Found $count targeting methods specified"
    exit 1
  fi

  echo "::notice::Targeting validation passed"
}

# Build targeting JSON for API request
build_targeting_json() {
  local all_servers="$1"
  local server_ids="$2"
  local tags="$3"
  local result=""

  echo "::debug::Building targeting JSON"

  if [[ "$all_servers" == "true" ]]; then
    echo "::debug::Using all_servers targeting"
    result=$(jq -n '{"all_servers": true}') || {
      echo "::error::Failed to build all_servers JSON"
      exit 1
    }
  elif [[ -n "$server_ids" ]]; then
    echo "::debug::Using server_ids targeting: $server_ids"
    # Convert comma-separated string to JSON array
    result=$(echo "$server_ids" | jq -R 'split(",") | map(select(length > 0)) | {server_ids: .}') || {
      echo "::error::Failed to parse server_ids. Expected comma-separated list of UUIDs."
      echo "::error::Received: $server_ids"
      exit 1
    }
  elif [[ -n "$tags" ]]; then
    echo "::debug::Using tags targeting: $tags"
    # Parse JSON tags string
    result=$(echo "$tags" | jq '{tags: .}') || {
      echo "::error::Failed to parse tags. Expected valid JSON object."
      echo "::error::Received: $tags"
      exit 1
    }
  fi

  if [[ -z "$result" ]]; then
    echo "::error::Failed to build targeting JSON - result is empty"
    exit 1
  fi

  echo "::debug::Targeting JSON built successfully: $result"
  echo "$result"
}
