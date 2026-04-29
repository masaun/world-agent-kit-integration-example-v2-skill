#!/usr/bin/env bash
# Create a new post inside an existing community via the
# world-agent-kit-integration-example-v2 Next.js app API.
#
# The API calls lookupHuman(address) on the AgentBook contract on World Chain
# mainnet when authorAddress is supplied. Unregistered addresses are rejected
# with 403 Forbidden. Omit the author address to create an anonymous post
# (AgentBook check is skipped entirely).
#
# Usage:
#   bash scripts/create_demo_post.sh <community-id> [author-address]
#
# Arguments:
#   community-id    UUID of the community to post into (required)
#   author-address  Registered agent wallet address (optional)
#
# Environment:
#   API_BASE_URL    Base URL of the Next.js app (default: http://localhost:3000)
#                   Auto-loaded from ~/.hermes/.env when present (Hermes Agent).
#
# Requires: curl

set -euo pipefail

# ── Load API_BASE_URL from ~/.hermes/.env when running inside Hermes Agent ────
HERMES_ENV="${HOME}/.hermes/.env"
if [[ -f "${HERMES_ENV}" ]]; then
  # shellcheck source=/dev/null
  set -a
  source "${HERMES_ENV}"
  set +a
fi

API_BASE_URL="${API_BASE_URL:-http://localhost:3000}"

# ── Parse arguments ───────────────────────────────────────────────────────────
COMMUNITY_ID="${1:-}"
AUTHOR_ADDRESS="${2:-}"

if [[ -z "${COMMUNITY_ID}" ]]; then
  echo "Error: community-id is required." >&2
  echo "Usage: bash scripts/create_demo_post.sh <community-id> [author-address]" >&2
  exit 1
fi

# Basic UUID format check (8-4-4-4-12 hex)
if [[ ! "${COMMUNITY_ID}" =~ ^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$ ]]; then
  echo "Error: '${COMMUNITY_ID}' does not look like a valid UUID." >&2
  echo "Expected format: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" >&2
  exit 1
fi

# Validate Ethereum address format when supplied
if [[ -n "${AUTHOR_ADDRESS}" ]]; then
  if [[ ! "${AUTHOR_ADDRESS}" =~ ^0x[0-9a-fA-F]{40}$ ]]; then
    echo "Error: '${AUTHOR_ADDRESS}' does not look like a valid Ethereum address." >&2
    echo "Expected format: 0x followed by 40 hex characters." >&2
    exit 1
  fi
fi

# ── Verify curl is available ──────────────────────────────────────────────────
if ! command -v curl &>/dev/null; then
  echo "Error: curl is required." >&2
  exit 1
fi

# ── Build request body ────────────────────────────────────────────────────────
POST_CONTENT="Hello from the agent!"

if [[ -n "${AUTHOR_ADDRESS}" ]]; then
  REQUEST_BODY="{\"content\":\"${POST_CONTENT}\",\"authorAddress\":\"${AUTHOR_ADDRESS}\"}"
else
  REQUEST_BODY="{\"content\":\"${POST_CONTENT}\"}"
fi

# ── Send request ──────────────────────────────────────────────────────────────
ENDPOINT="${API_BASE_URL}/api/communities/${COMMUNITY_ID}/posts"

echo "Creating post in community ${COMMUNITY_ID}..." >&2
if [[ -n "${AUTHOR_ADDRESS}" ]]; then
  echo "Author address: ${AUTHOR_ADDRESS}" >&2
  echo "(AgentBook on-chain registration check will be performed)" >&2
else
  echo "No author address supplied — anonymous post, AgentBook check skipped." >&2
fi
echo "Endpoint: ${ENDPOINT}" >&2

HTTP_RESPONSE=$(curl --silent --write-out "\n%{http_code}" \
  -X POST "${ENDPOINT}" \
  -H "Content-Type: application/json" \
  -d "${REQUEST_BODY}")

RESPONSE_BODY=$(echo "${HTTP_RESPONSE}" | head -n -1)
HTTP_STATUS=$(echo "${HTTP_RESPONSE}" | tail -n 1)

if [[ "${HTTP_STATUS}" == "201" ]]; then
  echo "Post created successfully (HTTP 201)." >&2
  echo "${RESPONSE_BODY}"
elif [[ "${HTTP_STATUS}" == "403" ]]; then
  echo "Error: AgentBook verification failed (HTTP 403)." >&2
  echo "The author address '${AUTHOR_ADDRESS}' is not registered in the AgentBook contract." >&2
  echo "Complete Step 2 (register_worldchain_agent.sh) before creating a post with an author address." >&2
  exit 3
elif [[ "${HTTP_STATUS}" == "404" ]]; then
  echo "Error: Community not found (HTTP 404)." >&2
  echo "Verify that community ID '${COMMUNITY_ID}' exists. Complete Step 3 first." >&2
  exit 4
elif [[ "${HTTP_STATUS}" == "400" ]]; then
  echo "Error: Bad request (HTTP 400)." >&2
  echo "Response: ${RESPONSE_BODY}" >&2
  exit 5
else
  echo "Error: Unexpected HTTP status ${HTTP_STATUS}." >&2
  echo "Response: ${RESPONSE_BODY}" >&2
  exit 6
fi
