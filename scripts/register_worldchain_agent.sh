#!/usr/bin/env bash
# Register an agent wallet address with the AgentBook contract on World Chain
# mainnet via WorldCoin AgentKit CLI.
#
# Usage:
#   bash scripts/register_worldchain_agent.sh <wallet-address>
#
# Requires: bun (https://bun.sh) — used for bunx

set -euo pipefail

AGENT_ADDRESS="${1:-}"

if [[ -z "${AGENT_ADDRESS}" ]]; then
  echo "Error: agent wallet address is required." >&2
  echo "Usage: bash scripts/register_worldchain_agent.sh <wallet-address>" >&2
  exit 1
fi

# Basic Ethereum address format check (0x + 40 hex chars)
if [[ ! "${AGENT_ADDRESS}" =~ ^0x[0-9a-fA-F]{40}$ ]]; then
  echo "Error: '${AGENT_ADDRESS}' does not look like a valid Ethereum address." >&2
  echo "Expected format: 0x followed by 40 hex characters." >&2
  exit 1
fi

# Verify bun is available (required for bunx)
if ! command -v bun &>/dev/null; then
  echo "Error: bun is required. Install from https://bun.sh" >&2
  exit 1
fi

echo "Registering agent ${AGENT_ADDRESS} with AgentBook on World Chain mainnet..." >&2

bunx @worldcoin/agentkit-cli register "${AGENT_ADDRESS}"
