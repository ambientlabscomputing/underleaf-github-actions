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
  echo "::debug::Full URL: ${full_url}"
  echo "::debug::Organization ID: ${org_id}"
  echo "::debug::Payload: ${payload}"

  # Make the API request
  local response
  local http_code
  local curl_exit_code
  
  response=$(curl -s -w "\n%{http_code}" \
    -X "${http_method}" \
    -H "Authorization: Bearer ${api_token}" \
    -H "X-Organization-ID: ${org_id}" \
    -H "Content-Type: application/json" \
    -d "${payload}" \
    "${full_url}" 2>&1)
  curl_exit_code=$?

  # Check if curl command itself failed
  if [[ $curl_exit_code -ne 0 ]]; then
    echo "::error::curl command failed with exit code: ${curl_exit_code}"
    echo "::error::This usually indicates a network error or invalid URL"
    echo "::error::Response/Error: ${response}"
    exit 1
  fi

  # Extract status code from last line
  http_code=$(echo "$response" | tail -n1)
  # Extract body (everything except last line)
  local body=$(echo "$response" | sed '$d')

  echo "::debug::HTTP Status Code: ${http_code}"

  # Check if request was successful
  if [[ "$http_code" != "200" && "$http_code" != "201" ]]; then
    echo "::error::━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "::error::API Request Failed"
    echo "::error::━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "::error::HTTP Status Code: ${http_code}"
    echo "::error::Endpoint: ${http_method} ${endpoint}"
    echo "::error::URL: ${full_url}"
    echo "::error::Organization ID: ${org_id}"
    echo "::error::━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "::error::Response Body:"
    echo "::error::${body}"
    echo "::error::━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Try to parse error message from JSON response
    local error_msg=$(echo "$body" | jq -r '.error // .message // "No error message provided"' 2>/dev/null)
    if [[ -n "$error_msg" && "$error_msg" != "null" ]]; then
      echo "::error::Error Message: ${error_msg}"
    fi
    
    exit 1
  fi

  echo "::debug::API request successful"
  # Return the response body
  echo "$body"
}
