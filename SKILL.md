---
name: world-agent-kit-integration-example-v2
description: >
  Generate a local agent key pair with bun + viem, register the wallet address
  with the AgentBook contract on World Chain mainnet via WorldCoin AgentKit CLI,
  and create a community via the world-agent-kit-integration-example-v2 Next.js
  app API (which verifies on-chain agent registration before persisting to Supabase).
---

# World AgentKit Integration Example v2 — Setup Skill

Set up an autonomous agent for the
[world-agent-kit-integration-example-v2](https://github.com/masaun/world-agent-kit-integration-example-v2)
Next.js community platform: generate a local key pair with `bun` and `viem`,
register the agent wallet address with the AgentBook contract via WorldCoin
AgentKit CLI, and create a community through the `/api/communities` endpoint
(which verifies on-chain registration before writing to Supabase).

---

## When to Use

- User wants to generate an agent wallet key pair for World Chain mainnet
- User wants to register an agent address with the AgentBook contract via WorldCoin AgentKit CLI
- User wants to create a community via the world-agent-kit-integration-example-v2 API
- Running through the full agent onboarding flow for this project
- User wants to verify an agent's registration status via `/api/agent/world-agent-kit/lookup-human`

---

## Prerequisites

- **`bun`** installed ([bun.sh](https://bun.sh)) — used for key pair generation and `bunx`
- **`viem`** available in the `app/` directory (run `bun install` inside `app/` first)
- **`curl`** available in shell
- The Next.js app running locally (`bun run dev` in `app/`) or deployed and reachable

Verify prerequisites:
```bash
bun --version
curl --version
```

---

## Available Scripts

- **`scripts/generate_agent_keypair.sh`** — Generates a random agent private key
  and derives the corresponding Ethereum wallet address using `bun` and `viem`.
  Outputs `private_key` and `wallet_address` as JSON. **Must be run from the `app/`
  directory** after `bun install`.
- **`scripts/register_worldchain_agent.sh`** — Registers an agent wallet address
  with the AgentBook contract on World Chain mainnet via
  `bunx @worldcoin/agentkit-cli register`.
- **`scripts/create_demo_community.sh`** — Creates a community via the
  `/api/communities` endpoint, passing the agent wallet address for on-chain
  verification against the AgentBook contract.

---

## Usage by Platform

### Hermes Agent
Add the skill to your project:
```bash
git clone https://github.com/masaun/world-agent-kit-integration-example-v2-skill.git ~/.hermes/skills/
```

### OpenClaw
Install into your workspace skills folder:
```bash
# Clone directly
git clone https://github.com/masaun/world-agent-kit-integration-example-v2-skill.git ~/.openclaw/workspace/skills/
```


---

## Workflow


### Step 1 — Create Privy Wallet with Policy

Create a Privy policy capping transactions at 0.001 ETH, restricted to
World Chain mainnet (chain ID `480`) and Base mainnet (chain ID `8453`),
then create a wallet with the policy attached:

```bash
bash scripts/create_privy_wallet.sh
```

The script prints JSON to stdout:
```json
{"wallet_id":"<id>","agent_address":"0x...","policy_id":"<id>"}
```

Save the `agent_address` for Steps 2 and 3.

---

or

### Step 1 — Generate Agent Key Pair

Install dependencies and generate the key pair from the `app/` directory:

```bash
cd app
bun install
bash ../scripts/generate_agent_keypair.sh
```

The script prints JSON to stdout:
```json
{"private_key":"0x...","wallet_address":"0x..."}
```

> **Important:** Store `private_key` securely. Set it as `AGENT_PRIVATE_KEY` in
> `app/.env.local`. Never commit it or expose it to the browser.

Save the `wallet_address` for Steps 2 and 3.

---

### Step 2 — Register Agent with World AgentKit

At first, asking the user for which <wallet-address> the user wants to register. This should be the `agent_address` from Step 1 if using the Privy wallet flow.

Register the wallet address obtained in Step 1:

```bash
bash scripts/register_worldchain_agent.sh "<wallet-address>"
```

This runs:
```bash
npx @worldcoin/agentkit-cli register <wallet-address>
```

Display the QR code image in the `Messaging platforms` after the agentkit-cli register command produces the World App verification link.

What I did:
- Ran the registration command
- Captured the verification URL it printed
- Generated a QR code image from that URL
- Checked the QR image visually to confirm it’s clear and scannable

The QR code image was saved here:
`/tmp/worldcoin-agentkit-verify.png`

Scan the QR code with the World App to complete verification. This proves ownership of the wallet address and links it to a human identity in the World system.

Once the verification is complete, the agent is now registered in the AgentBook contract on World Chain mainnet.

Once the agent is registered, the QR code image saved should be deleted automatically by the following script:
```bash
rm /tmp/worldcoin-agentkit-verify.png
```

---

### Step 3 — Create Community

Create a community linked to the registered agent wallet:

```bash
bash scripts/create_demo_community.sh "<wallet-address>"
```

This sends:
```bash
curl -X POST ${API_BASE_URL}/api/communities \
     -H "Content-Type: application/json" \
     -d '{
       "name": "Demo Community by Agent",
       "description": "This is the Demo Community created by Agent",
       "agentWalletAddress": "<wallet-address>"
     }'
```

The API calls `lookupHuman(address)` on the AgentBook contract — if the agent is
not registered it returns `403 Forbidden`. On success it returns the newly created
community as JSON and persists it to Supabase.

#### API Base URL
Read `API_BASE_URL` from `~/.hermes/.env` if available - if Hernes Agent.

Or, Set `API_BASE_URL` if not targeting `http://localhost:3000` (the default):
```bash
export API_BASE_URL=https://your-deployment.vercel.app
bash scripts/create_demo_community.sh "<wallet-address>"
```

---

### (Optional) Step 4 — Verify Agent Registration

Look up the human nullifier hash linked to the agent:

```bash
curl "${API_BASE_URL:-http://localhost:3000}/api/agent/world-agent-kit/lookup-human?agentWalletAddress=<wallet-address>"
```

Response:
```json
{"agentWalletAddress":"0x...","humanId":"<nullifier-hash>","registered":true}
```

`registered: true` confirms the agent is backed by a real human (non-zero `humanId`).

---

### (Optional) Step 5 — Run Demo Agent

Trigger the full AgentKit demo request sequence against `/api/data`. The agent
signs SIWE messages locally (private key never leaves the agent) and sends
pre-built AgentKit headers in the POST body:

```bash
curl -X POST "${API_BASE_URL:-http://localhost:3000}/api/agent/world-agent-kit" \
     -H "Content-Type: application/json" \
     -d '{
       "agentWalletAddress": "<wallet-address>",
       "agentkitHeaders": ["<signed-header-1>", "<signed-header-2>", ...]
     }'
```

See the app README and `app/src/lib/agent/world-agent-kit/` for the demo signing
script that builds these headers locally.

---

## App Environment Variables

Copy `app/.env.example` to `app/.env.local` and fill in:

```bash
# ── Supabase (required) ──────────────────────────────────────────────────────
# Find these in: Supabase dashboard → Project → Settings → API
NEXT_PUBLIC_SUPABASE_URL=https://<project-ref>.supabase.co
# Service role key — server-side only. NEVER add NEXT_PUBLIC_ prefix.
SUPABASE_SERVICE_ROLE_KEY=<service-role-key>

# ── Agent ────────────────────────────────────────────────────────────────────
# Agent private key from Step 1 (hex, with 0x prefix)
AGENT_PRIVATE_KEY=<hex-private-key>

# ── AgentKit demo settings ───────────────────────────────────────────────────
# Number of free-trial uses per registered agent (default: 3)
FREE_TRIAL_USES=3
# Payment recipient address on World Chain
PAY_TO=0xYourPaymentAddressHere
# World Chain CAIP-2 identifier (default: eip155:480)
WORLD_CHAIN_MAINNET_INDENTIFIER=eip155:480
# USDC contract on World Chain
USCO_ON_WORLD_CHAIN_MAINNET=0x79A02482A880bCE3F13e09Da970dC34db4CD24d1

# ── Overrides (optional) ─────────────────────────────────────────────────────
# AgentBook contract address on World Chain mainnet
NEXT_PUBLIC_AGENT_BOOK_ON_WORLD_CHAIN_MAINNET=0xa23ab2712ea7bba896930544c7d6636a96b944da
# World Chain RPC URL (use an Alchemy key for production)
NEXT_PUBLIC_WORLD_CHAIN_RPC_URL=https://worldchain-mainnet.g.alchemy.com/public
# Number of requests in the demo loop (default: 4)
NEXT_PUBLIC_DEMO_REQUESTS=4
```

### Supabase setup

1. Create a project at [supabase.com](https://supabase.com/)
2. Run `app/supabase-migration.sql` in the Supabase SQL editor to create the
   `communities` and `posts` tables
3. Copy `NEXT_PUBLIC_SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY` into
   `app/.env.local` from Settings → API

> **Why the service role key?** All Supabase calls happen server-side (API routes
> and Server Components). The service role key bypasses Row Level Security and is
> never sent to the browser. The anon key would block all inserts/reads without
> explicit RLS policies.

---

## Pitfalls

- **`bun` not in PATH** — Install from [bun.sh](https://bun.sh). Check with `bun --version`.
- **`viem` not found** — Run `bun install` inside `app/` before running
  `generate_agent_keypair.sh`. The script must be run from the `app/` directory.
- **Key idempotency** — Running Step 1 multiple times creates new key pairs. Reuse
  the `wallet_address` from the first run for Steps 2 and 3.
- **Registration required** — The `/api/communities` endpoint returns `403 Forbidden`
  if `agentWalletAddress` is not registered in AgentBook. Complete Step 2 before Step 3.
- **World Chain chain ID** — World Chain mainnet uses chain ID `480`
  (CAIP-2: `eip155:480`).
- **Service role key** — Use `SUPABASE_SERVICE_ROLE_KEY` (not the anon key). Never
  prefix it with `NEXT_PUBLIC_`.