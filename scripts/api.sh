#!/bin/bash
set -euo pipefail

# Make an authenticated API request to Underleaf
# Args: $1 = API_URL, $2 = API_TOKEN, $3 = ORG_ID, $4 = HTTP_METHOD, $5 = ENDPOINT, $6 = JSON_PAYLOAD
make_api_request() {
  local api_url="$1"
  local api_token="$2"
  local org_id="$3"
  local http_method="$4"
  local endpoint="$5"
  local payload="$6"

  local full_url="${api_url}${endpoint}"
  
  echo "::notice::Sending ${http_method} request to ${endpoint}"

  # Make the API request
  local response
  local http_code
  
  response=$(curl -s -w "\n%{http_code}" \
    -X "${http_method}" \
    -H "Authorization: Bearer ${api_token}" \
    -H "X-Organization-ID: ${org_id}" \
    -H "Content-Type: application/json" \
    -d "${payload}" \
    "${full_url}")

  # Extract status code from last line
  http_code=$(echo "$response" | tail -n1)
  # Extract body (everything except last line)
  local body=$(echo "$response" | sed '$d')

  # Check if request was successful
  if [[ "$http_code" != "200" ]]; then
    echo "::error::API request failed with status code: ${http_code}"
    echo "::error::Response: ${body}"
    exit 1
  fi

  # Return the response body
  echo "$body"
}
