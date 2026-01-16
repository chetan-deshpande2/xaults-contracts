# Xaults AssetToken

This is a **UUPS upgradeable ERC-20** token implementation designed for tokenized financial assets. It currently includes two versions:
- **V1**: Basic ERC-20 with role-based access control (Admin/Minter), capped supply, and UUPS upgradeability.
- **V2**: Adds emergency pause functionality for compliance.

---

## 🛠 Setup

First, install Foundry if you haven't already:
```bash
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

Then clone and install dependencies:
```bash
git clone <repo-url>
cd xalts-contracts
forge install
```

---

## 🧪 Running Tests

I've included a comprehensive test suite covering unit tests, invariant tests, and the upgrade lifecycle.

```bash
# Run all tests (Unit + Invariant)
forge test -vvv

# Run only unit tests
export POLYGON_RPC_URL=https://polygon-rpc.com
forge test --match-path "test/unit/*" -vvv

# Run verification on a Polygon mainnet fork (Free, no API key needed)
export POLYGON_RPC_URL=https://polygon-rpc.com
forge test --fork-url polygon -vvv
```

---

##  Deployment (Local)

You can verify the entire lifecycle (Deploy V1 -> Mint -> Upgrade V2 -> Pause) locally using Anvil.

### 1. Start Local Chain
```bash
anvil
```

### 2. Deploy V1
```bash
# In a new terminal
export PRIVATE_KEY=your_private_key_here
forge script script/Deploy.s.sol --rpc-url http://127.0.0.1:8545 --broadcast --private-key $PRIVATE_KEY
```
*Take note of the `Proxy` address in the output.*

### 3. Upgrade to V2
```bash
export PROXY_ADDRESS=<YOUR_PROXY_ADDRESS>
export PRIVATE_KEY=your_private_key_here
forge script script/UpgradeToV2.s.sol --rpc-url http://127.0.0.1:8545 --broadcast --private-key $PRIVATE_KEY
```

### 4. CLI Interaction (Manual Minting)
Here is how you would manually interact with the deployed contract to mint tokens using `cast`:

```bash
# Mint 100 tokens to a specific address
cast send $PROXY_ADDRESS "mint(address,uint256)" \
  <RECIPIENT_ADDRESS> 100000000000000000000 \
  --rpc-url http://127.0.0.1:8545 \
  --private-key $PRIVATE_KEY

# Verify balance
cast call $PROXY_ADDRESS "balanceOf(address)(uint256)" <RECIPIENT_ADDRESS> \
  --rpc-url http://127.0.0.1:8545
```

---

## Storage Layout Verification

Ensuring storage safety during upgrades is critical to avoid corrupting state (like overwriting the token name or balances).

**How I verified this:**

I used the standard OpenZeppelin storage gap pattern (`__gap`) to reserve slots. Since V2 brings in `PausableUpgradeable`, which uses storage, I manually reduced the gap size in V2 (from 49 to 48) to compensate. This keeps the storage alignment identical for all subsequent variables.

You can double-check the slots match up by running:
```bash
forge inspect AssetToken storage-layout --pretty
forge inspect AssetTokenV2 storage-layout --pretty
```
If you compare the output, you'll see `_maxSupply` and other state vars sit at the exact same slots in both versions.

---

## Contract Details

### AssetToken (V1)
- **Roles:**
  - `DEFAULT_ADMIN_ROLE`: Can upgrade implementation.
  - `MINTER_ROLE`: Can mint new tokens.
- **Features:**
  - `initialize()` pattern (no constructor).
  - Capped supply (defined on deployment).
  - ERC20Permit for gasless approvals.

### AssetTokenV2
- **New Features:**
  - `pause()` / `unpause()`: Admin only.
  - While paused, **all** transfers (including mint/burn) revert.
