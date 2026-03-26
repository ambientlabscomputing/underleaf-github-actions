#!/bin/bash
set -euo pipefail

# Poll a job until it reaches a terminal state (success or failure).
#
# Usage:
#   source scripts/poll.sh
#   poll_job "$API_URL" "$API_TOKEN" "$ORG_ID" "$JOB_ID" "$TIMEOUT" "$POLL_INTERVAL"
#
# Returns: sets POLL_STATUS (success|failure) and POLL_DURATION (seconds elapsed).
# Exits non-zero if the job fails, times out, or an API error occurs.
poll_job() {
  local api_url="$1"
  local api_token="$2"
  local org_id="$3"
  local job_id="$4"
  local timeout="${5:-600}"
  local interval="${6:-10}"

  local start_time elapsed status
  start_time=$(date +%s)

  echo "::group::Waiting for job $job_id (timeout: ${timeout}s, interval: ${interval}s)"
  echo "::notice::Polling job $job_id..."

  while true; do
    elapsed=$(( $(date +%s) - start_time ))

    if [[ $elapsed -ge $timeout ]]; then
      echo "::endgroup::"
      echo "::error::Job $job_id timed out after ${elapsed}s"
      POLL_STATUS="timeout"
      POLL_DURATION="$elapsed"
      exit 1
    fi

    # Fetch job status
    local response http_code body curl_exit_code
    response=$(curl -s -w "\n%{http_code}" \
      -H "Authorization: Bearer ${api_token}" \
      -H "X-Organization-ID: ${org_id}" \
      "${api_url}/api/v1/servers/jobs/${job_id}" 2>&1)
    curl_exit_code=$?

    if [[ $curl_exit_code -ne 0 ]]; then
      echo "::warning::curl failed (exit $curl_exit_code), retrying in ${interval}s..."
      sleep "$interval"
      continue
    fi

    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')

    if [[ "$http_code" != "200" ]]; then
      echo "::warning::Job poll returned HTTP $http_code, retrying in ${interval}s..."
      echo "::debug::Response: $body"
      sleep "$interval"
      continue
    fi

    status=$(echo "$body" | jq -r '.status // "unknown"' 2>/dev/null || echo "unknown")
    echo "::debug::Job $job_id status=$status elapsed=${elapsed}s"

    case "$status" in
      completed|success)
        echo "::endgroup::"
        echo "::notice::✅ Job $job_id completed successfully (${elapsed}s)"
        POLL_STATUS="success"
        POLL_DURATION="$elapsed"
        return 0
        ;;
      failed|failure|error)
        local error_msg
        error_msg=$(echo "$body" | jq -r '.error // .message // "no details"' 2>/dev/null || echo "no details")
        echo "::endgroup::"
        echo "::error::━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "::error::Job $job_id failed after ${elapsed}s"
        echo "::error::Error: $error_msg"
        echo "::error::━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        POLL_STATUS="failure"
        POLL_DURATION="$elapsed"
        exit 1
        ;;
      running|pending|in_progress|queued)
        echo "::notice::Job $job_id is $status... (${elapsed}s elapsed)"
        sleep "$interval"
        ;;
      *)
        echo "::warning::Unknown job status '$status', retrying in ${interval}s..."
        sleep "$interval"
        ;;
    esac
  done
}
