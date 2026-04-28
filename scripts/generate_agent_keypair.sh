#!/usr/bin/env bash
# Generate a random agent private key and derive the corresponding Ethereum
# wallet address using bun + viem.
#
# Usage (from the app/ directory after `bun install`):
#   bash ../scripts/generate_agent_keypair.sh
#
# Output (stdout): JSON — {"private_key":"0x...","wallet_address":"0x..."}
# Diagnostics:     stderr
#
# Requires:
#   - bun (https://bun.sh)
#   - viem installed in the current directory's node_modules
#     (run `bun install` inside app/ first, then run this script from app/)

set -euo pipefail

# ── Validate bun is available ─────────────────────────────────────────────────
if ! command -v bun &>/dev/null; then
  echo "Error: bun is required. Install from https://bun.sh" >&2
  exit 1
fi

# ── Validate viem is installed ────────────────────────────────────────────────
if [[ ! -d "node_modules/viem" ]]; then
  echo "Error: viem not found in node_modules." >&2
  echo "Run 'bun install' inside the app/ directory, then re-run this script from app/." >&2
  exit 1
fi

# ── Step 1: Generate random private key ──────────────────────────────────────
echo "Generating agent private key..." >&2

AGENT_PRIVATE_KEY=$(bun -e "console.log('0x' + require('crypto').randomBytes(32).toString('hex'))")

if [[ -z "${AGENT_PRIVATE_KEY}" ]]; then
  echo "Error: Failed to generate private key." >&2
  exit 2
fi

# ── Step 2: Derive wallet address with viem ───────────────────────────────────
echo "Deriving wallet address from private key..." >&2

AGENT_WALLET_ADDRESS=$(VIEM_KEY="${AGENT_PRIVATE_KEY}" bun -e "
  const { privateKeyToAccount } = require('viem/accounts');
  const account = privateKeyToAccount(process.env.VIEM_KEY);
  console.log(account.address);
")

if [[ -z "${AGENT_WALLET_ADDRESS}" ]]; then
  echo "Error: Failed to derive wallet address." >&2
  exit 3
fi

echo "Key pair generated successfully." >&2
echo "" >&2
echo "IMPORTANT: Store the private key securely. Set it as AGENT_PRIVATE_KEY in app/.env.local." >&2
echo "" >&2

# ── Output ────────────────────────────────────────────────────────────────────
printf '{"private_key":"%s","wallet_address":"%s"}\n' \
  "${AGENT_PRIVATE_KEY}" "${AGENT_WALLET_ADDRESS}"
