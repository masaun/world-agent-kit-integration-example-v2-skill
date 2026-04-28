#!/usr/bin/env bash
# Create a community linked to a registered agent wallet address via the
# world-agent-kit-integration-example-v2 /api/communities endpoint.
#
# The API verifies the agent wallet address is registered in the AgentBook
# contract on World Chain mainnet before persisting the community to Supabase.
#
# Usage:
#   bash scripts/create_demo_community.sh <wallet-address>
#
# Environment:
#   API_BASE_URL  — base URL of the Next.js app (default: http://localhost:3000)
#
# Requires: curl

set -euo pipefail

AGENT_ADDRESS="${1:-}"

if [[ -z "${AGENT_ADDRESS}" ]]; then
  echo "Error: agent wallet address is required." >&2
  echo "Usage: bash scripts/create_demo_community.sh <wallet-address>" >&2
  exit 1
fi

# Basic Ethereum address format check (0x + 40 hex chars)
if [[ ! "${AGENT_ADDRESS}" =~ ^0x[0-9a-fA-F]{40}$ ]]; then
  echo "Error: '${AGENT_ADDRESS}' does not look like a valid Ethereum address." >&2
  echo "Expected format: 0x followed by 40 hex characters." >&2
  exit 1
fi

API_BASE_URL="${API_BASE_URL:-http://localhost:3000}"
COMMUNITIES_API="${API_BASE_URL}/api/communities"

echo "Creating community 'Demo Community by Agent' at ${COMMUNITIES_API}..." >&2

RESPONSE=$(curl -sS -w "\n%{http_code}" -X POST "${COMMUNITIES_API}" \
  -H "Content-Type: application/json" \
  -d "{
    \"name\": \"Demo Community by Agent\",
    \"description\": \"This is the Demo Community created by Agent\",
    \"agentWalletAddress\": \"${AGENT_ADDRESS}\"
  }")

HTTP_CODE=$(echo "${RESPONSE}" | tail -1)
BODY=$(echo "${RESPONSE}" | head -n -1)

if [[ "${HTTP_CODE}" != "200" && "${HTTP_CODE}" != "201" ]]; then
  echo "Error: Community creation failed (HTTP ${HTTP_CODE})." >&2
  echo "${BODY}" >&2
  exit 2
fi

echo "Community created successfully." >&2
echo "${BODY}"
