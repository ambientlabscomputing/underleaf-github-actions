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
  
  echo "::notice::Sending ${http_method} request to ${endpoint}" >&2
  echo "::debug::Full URL: ${full_url}" >&2
  echo "::debug::Organization ID: ${org_id}" >&2
  echo "::debug::Payload: ${payload}" >&2

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
    echo "::error::curl command failed with exit code: ${curl_exit_code}" >&2
    echo "::error::This usually indicates a network error or invalid URL" >&2
    echo "::error::Response/Error: ${response}" >&2
    exit 1
  fi

  # Extract status code from last line
  http_code=$(echo "$response" | tail -n1)
  # Extract body (everything except last line)
  local body=$(echo "$response" | sed '$d')

  echo "::debug::HTTP Status Code: ${http_code}" >&2

  # Check if request was successful
  if [[ "$http_code" != "200" && "$http_code" != "201" ]]; then
    echo "::error::━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
    echo "::error::API Request Failed" >&2
    echo "::error::━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
    echo "::error::HTTP Status Code: ${http_code}" >&2
    echo "::error::Endpoint: ${http_method} ${endpoint}" >&2
    echo "::error::URL: ${full_url}" >&2
    echo "::error::Organization ID: ${org_id}" >&2
    echo "::error::━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
    echo "::error::Response Body:" >&2
    echo "::error::${body}" >&2
    echo "::error::━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
    
    # Try to parse error message from JSON response
    local error_msg=$(echo "$body" | jq -r '.error // .message // "No error message provided"' 2>/dev/null)
    if [[ -n "$error_msg" && "$error_msg" != "null" ]]; then
      echo "::error::Error Message: ${error_msg}" >&2
    fi
    
    exit 1
  fi

  echo "::debug::API request successful" >&2
  # Return the response body
  echo "$body"
}

# Make an authenticated API request with YAML body (for infra endpoints)
# Args: same as make_api_request but body is treated as raw YAML
make_yaml_api_request() {
  local api_url="$1"
  local api_token="$2"
  local org_id="$3"
  local http_method="$4"
  local endpoint="$5"
  local file_path="$6"

  local full_url="${api_url}${endpoint}"

  echo "::notice::Sending ${http_method} YAML request to ${endpoint}" >&2
  echo "::debug::Full URL: ${full_url}" >&2

  local response http_code curl_exit_code

  response=$(curl -s -w "\n%{http_code}" \
    -X "${http_method}" \
    -H "Authorization: Bearer ${api_token}" \
    -H "X-Organization-ID: ${org_id}" \
    -H "Content-Type: application/x-yaml" \
    --data-binary "@${file_path}" \
    "${full_url}" 2>&1)
  curl_exit_code=$?

  if [[ $curl_exit_code -ne 0 ]]; then
    echo "::error::curl command failed with exit code: ${curl_exit_code}" >&2
    echo "::error::Response/Error: ${response}" >&2
    exit 1
  fi

  http_code=$(echo "$response" | tail -n1)
  local body
  body=$(echo "$response" | sed '$d')

  if [[ "$http_code" != "200" && "$http_code" != "201" ]]; then
    echo "::error::━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
    echo "::error::API Request Failed" >&2
    echo "::error::HTTP Status Code: ${http_code}" >&2
    echo "::error::Endpoint: ${http_method} ${endpoint}" >&2
    echo "::error::Response Body: ${body}" >&2
    echo "::error::━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
    local error_msg
    error_msg=$(echo "$body" | jq -r '.error // .message // "No error message provided"' 2>/dev/null)
    if [[ -n "$error_msg" && "$error_msg" != "null" ]]; then
      echo "::error::Error Message: ${error_msg}" >&2
    fi
    exit 1
  fi

  echo "$body"
}

# Make an authenticated DELETE request (no body, accepts 200/204)
# Args: $1 = API_URL, $2 = API_TOKEN, $3 = ORG_ID, $4 = ENDPOINT
make_api_delete() {
  local api_url="$1"
  local api_token="$2"
  local org_id="$3"
  local endpoint="$4"

  local full_url="${api_url}${endpoint}"

  echo "::notice::Sending DELETE request to ${endpoint}" >&2

  local http_code curl_exit_code

  http_code=$(curl -s -o /dev/null -w "%{http_code}" \
    -X DELETE \
    -H "Authorization: Bearer ${api_token}" \
    -H "X-Organization-ID: ${org_id}" \
    "${full_url}" 2>&1)
  curl_exit_code=$?

  if [[ $curl_exit_code -ne 0 ]]; then
    echo "::warning::DELETE curl failed (exit $curl_exit_code) for ${endpoint}" >&2
    return 1
  fi

  if [[ "$http_code" != "200" && "$http_code" != "204" ]]; then
    echo "::warning::DELETE ${endpoint} returned HTTP $http_code" >&2
    return 1
  fi

  echo "::debug::DELETE ${endpoint} succeeded" >&2
  return 0
}
