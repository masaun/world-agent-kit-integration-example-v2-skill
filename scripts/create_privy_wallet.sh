#!/usr/bin/env bash
# Create a Privy policy + Ethereum agent wallet
#
# Policy enforces:
#   - Max 0.001 ETH (1000000000000000 wei) per transaction
#   - Chain restricted to World Chain mainnet (480) and Base mainnet (8453)
#
# Usage:
#   export PRIVY_APP_ID=...
#   export PRIVY_APP_SECRET=...
#   bash scripts/create_privy_wallet.sh
#
# Output (stdout): JSON — {"wallet_id":"...","agent_address":"0x...","policy_id":"..."}
# Diagnostics:     stderr

set -euo pipefail

# ── Validate credentials ──────────────────────────────────────────────────────
if [[ -z "${PRIVY_APP_ID:-}" || -z "${PRIVY_APP_SECRET:-}" ]]; then
  echo "Error: PRIVY_APP_ID and PRIVY_APP_SECRET must be set." >&2
  echo "Usage: export PRIVY_APP_ID=<id> && export PRIVY_APP_SECRET=<secret> && bash scripts/create_privy_wallet.sh" >&2
  exit 1
fi

PRIVY_BASE_URL="https://api.privy.io"

# ── Step 1: Create policy ─────────────────────────────────────────────────────
echo "Creating Privy policy (0.001 ETH max, World Chain + Base mainnet)..." >&2

POLICY_RESPONSE=$(curl -sS -w "\n%{http_code}" -X POST "${PRIVY_BASE_URL}/v1/policies" \
  --user "${PRIVY_APP_ID}:${PRIVY_APP_SECRET}" \
  -H "privy-app-id: ${PRIVY_APP_ID}" \
  -H "Content-Type: application/json" \
  -d '{
    "version": "1.0",
    "name": "OpenBands agent policy — 0.001 ETH max, World Chain + Base mainnet",
    "chain_type": "ethereum",
    "rules": [
      {
        "name": "Max 0.001 ETH per tx on World Chain or Base mainnet",
        "method": "eth_sendTransaction",
        "conditions": [
          {
            "field_source": "ethereum_transaction",
            "field": "value",
            "operator": "lte",
            "value": "1000000000000000"
          },
          {
            "field_source": "ethereum_transaction",
            "field": "chain_id",
            "operator": "in",
            "value": ["480", "8453"]
          }
        ],
        "action": "ALLOW"
      }
    ]
  }')

POLICY_HTTP_CODE=$(echo "${POLICY_RESPONSE}" | tail -1)
POLICY_BODY=$(echo "${POLICY_RESPONSE}" | head -n -1)

if [[ "${POLICY_HTTP_CODE}" != "200" && "${POLICY_HTTP_CODE}" != "201" ]]; then
  echo "Error: Policy creation failed (HTTP ${POLICY_HTTP_CODE})." >&2
  echo "${POLICY_BODY}" >&2
  exit 2
fi

POLICY_ID=$(echo "${POLICY_BODY}" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)

if [[ -z "${POLICY_ID}" ]]; then
  echo "Error: Could not parse policy ID from response." >&2
  echo "${POLICY_BODY}" >&2
  exit 2
fi

echo "Policy created: ${POLICY_ID}" >&2

# ── Step 2: Create wallet with policy ────────────────────────────────────────
echo "Creating Ethereum agent wallet..." >&2

WALLET_RESPONSE=$(curl -sS -w "\n%{http_code}" -X POST "${PRIVY_BASE_URL}/v1/wallets" \
  --user "${PRIVY_APP_ID}:${PRIVY_APP_SECRET}" \
  -H "privy-app-id: ${PRIVY_APP_ID}" \
  -H "Content-Type: application/json" \
  -d "{
    \"chain_type\": \"ethereum\",
    \"policy_ids\": [\"${POLICY_ID}\"]
  }")

WALLET_HTTP_CODE=$(echo "${WALLET_RESPONSE}" | tail -1)
WALLET_BODY=$(echo "${WALLET_RESPONSE}" | head -n -1)

if [[ "${WALLET_HTTP_CODE}" != "200" && "${WALLET_HTTP_CODE}" != "201" ]]; then
  echo "Error: Wallet creation failed (HTTP ${WALLET_HTTP_CODE})." >&2
  echo "${WALLET_BODY}" >&2
  exit 3
fi

WALLET_ID=$(echo "${WALLET_BODY}" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
AGENT_ADDRESS=$(echo "${WALLET_BODY}" | grep -o '"address":"[^"]*"' | head -1 | cut -d'"' -f4)

if [[ -z "${WALLET_ID}" || -z "${AGENT_ADDRESS}" ]]; then
  echo "Error: Could not parse wallet ID or address from response." >&2
  echo "${WALLET_BODY}" >&2
  exit 3
fi

echo "Wallet created: ${WALLET_ID}" >&2
echo "Agent address:  ${AGENT_ADDRESS}" >&2

# ── Output ────────────────────────────────────────────────────────────────────
printf '{"wallet_id":"%s","agent_address":"%s","policy_id":"%s"}\n' \
  "${WALLET_ID}" "${AGENT_ADDRESS}" "${POLICY_ID}"
