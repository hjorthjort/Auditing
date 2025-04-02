# Shadow Exchange x3,3

Shadow Exchange on Sonic mainnet (core inherited from ShadowV3) introduces a novel vote-governance structure tailored for the Sonic ecosystem.

- **Website:** [https://www.shadowdex.fi/](https://www.shadowdex.fi/)
- **Twitter(X):** [https://x.com/ShadowDexFi](https://x.com/ShadowDexFi)
- **Discord:** [https://discord.com/invite/shadowexchange](https://discord.com/invite/shadowexchange)

---

## Development & Deployment Guide

### Prerequisites
- [Foundry](https://github.com/foundry-rs/foundry) installed.
- `.env` file configured with the required environment variables.

---

## Local Setup (Anvil)

### Build
```bash
forge build
```

### Test
```bash
forge test
```

### Source Environment
```bash
source .env
```

---

## Deployment Instructions (Sonic)

**Note:** Ensure `.env` is set with `$SONIC_RPC`, `$SONIC_RPC_TESTNET`, `$PRIVATE_KEY`.

## SONIC TESTNET

### Deploy `RewardsClaimers` 
```bash
forge create contracts/libraries/RewardClaimers.sol:RewardClaimers \
--rpc-url $SONIC_RPC_TESTNET \
--private-key $PRIVATE_KEY \
--broadcast \
--verify \
--verifier-url $SONICSCAN_TESTNET_URL \
--verifier-api-key $SONICSCAN_TESTNET_API_KEY
```


### Deploy Individual Non-CLContracts

#### These contracts are the ones that are not circular dependent on each other. On this step, voter is just deployed not initialized. 
```bash
forge script scripts/foundry/non-cl/DeployIndividualContracts.sol:DeployIndividualContracts \
--rpc-url $SONIC_RPC_TESTNET \
--private-key $PRIVATE_KEY \
--broadcast \
--verify \
--verifier-url $SONICSCAN_TESTNET_URL \
--verifier-api-key $SONICSCAN_TESTNET_API_KEY
```

### Deploy CL Core
```bash
forge script scripts/foundry/cl/core/DeployCLFull.sol:DeployCLFull \
--rpc-url $SONIC_RPC_TESTNET \
--private-key $PRIVATE_KEY \
--broadcast \
--verify \
--verifier-url $SONICSCAN_TESTNET_URL \
--verifier-api-key $SONICSCAN_TESTNET_API_KEY
```

### Deploy CL Periphery
```bash
forge script scripts/foundry/cl/periphery/DeployPeripheryFull.sol:DeployPeripheryFull \
--rpc-url $SONIC_RPC_TESTNET \
--private-key $PRIVATE_KEY \
--broadcast \
--verify \
--verifier-url $SONICSCAN_TESTNET_URL \
--verifier-api-key $SONICSCAN_TESTNET_API_KEY
```

### Deploy CL Gauge
```bash
forge script scripts/foundry/cl/gauge/DeployGaugeFull.sol:DeployGaugeFull \
--rpc-url $SONIC_RPC_TESTNET \
--private-key $PRIVATE_KEY \
--broadcast \
--verify \
--verifier-url $SONICSCAN_TESTNET_URL \
--verifier-api-key $SONICSCAN_TESTNET_API_KEY
```

### Deploy CL Universal Router
```bash
forge script scripts/foundry/cl/universalRouter/DeployUniversalRouterFull.sol:DeployUniversalRouterFull \
--rpc-url $SONIC_RPC_TESTNET \
--private-key $PRIVATE_KEY \
--broadcast \
--verify \
--verifier-url $SONICSCAN_TESTNET_URL \
--verifier-api-key $SONICSCAN_TESTNET_API_KEY
```

### Deploy Non-CLDependent Contracts

#### These contracts are the ones that are circular dependent on each other. On this step, voter is initialized with various parameters.
```bash
forge script scripts/foundry/non-cl/DeployVoterDependent.sol:DeployVoterDependent \
--rpc-url $SONIC_RPC_TESTNET \
--private-key $PRIVATE_KEY \
--broadcast \
--verify \
--verifier-url $SONICSCAN_TESTNET_URL \
--verifier-api-key $SONICSCAN_TESTNET_API_KEY
```

---

## SONIC MAINNET
### For Sonic Mainnet, you can use the same deployment order as the testnet. Just make sure to use the correct RPC URL and private key for the mainnet.


## Suggested Deployment Order

1. Configure [`scripts/foundry/non-cl/config`](scripts/foundry/non-cl/config/testnet.json) or [`scripts/foundry/non-cl/config`](scripts/foundry/non-cl/config/mainnet.json) with configuration info.
2. Deploy [`contracts/libraries/RewardClaimers.sol:RewardClaimers`](contracts/libraries/RewardClaimers.sol).
3. Deploy [`scripts/foundry/non-cl/DeployIndividualContracts.sol`](scripts/foundry/non-cl/DeployIndividualContracts.sol).
4. Configure [`scripts/foundry/cl/core/config/testnet.json`](scripts/foundry/cl/core/config/testnet.json) or [`scripts/foundry/cl/core/config/mainnet.json`](scripts/foundry/cl/core/config/mainnet.json) with required info.
5. Deploy [`scripts/foundry/cl/core/DeployCLFull.sol:DeployCLFull`](scripts/foundry/cl/core/DeployCLFull.sol).
6. Configure [`scripts/foundry/cl/periphery/config/testnet.json`](scripts/foundry/cl/periphery/config/testnet.json) or [`scripts/foundry/cl/periphery/config/mainnet.json`](scripts/foundry/cl/periphery/config/mainnet.json) with required info.
7. Deploy [`scripts/foundry/cl/periphery/DeployPeripheryFull.sol:DeployPeripheryFull`](scripts/foundry/cl/periphery/DeployPeripheryFull.sol).
8. Configure [`scripts/foundry/cl/gauge/config`](scripts/foundry/cl/gauge/config/testnet.json) or [`scripts/foundry/cl/gauge/config`](scripts/foundry/cl/gauge/config/mainnet.json) with required info.
9. Deploy [`scripts/foundry/cl/gauge/DeployGaugeBase.sol:DeployGaugeBase`](scripts/foundry/cl/gauge/DeployGaugeBase.sol).
10. Configure [`scripts/foundry/cl/universalRouter/config/testnet.json`](scripts/foundry/cl/universalRouter/config/testnet.json) or [`scripts/foundry/cl/universalRouter/config/mainnet.json`](scripts/foundry/cl/universalRouter/config/mainnet.json) with required info.
11. Deploy [`scripts/foundry/cl/universalRouter/DeployUniversalRouterBase.sol:DeployUniversalRouterBase`](scripts/foundry/cl/universalRouter/DeployUniversalRouterBase.sol).
12. Update [`scripts/foundry/non-cl/config/testnet.json`](scripts/foundry/non-cl/config/testnet.json) or [`scripts/foundry/non-cl/config/mainnet.json`](scripts/foundry/non-cl/config/mainnet.json) with NFP and CLFactory info.
13. Deploy [`scripts/foundry/non-cl/DeployVoterDependent.sol:DeployVoterDependent`](scripts/foundry/non-cl/DeployVoterDependent.sol).


---

### Verify Contracts Sonic Testnet (If it didn't work on the deployment)

```bash
forge verify-contract --watch --verifier etherscan --etherscan-api-key [APY_KEY] --verifier-url 'https://api-testnet.sonicscan.org/api' [CONTRACT_ADDRESS] --constructor-args [BUILD_ARGS] contracts/AccessHub.sol:AccessHub
```

```bash
forge verify-contract --watch --verifier etherscan --etherscan-api-key [APY_KEY] --verifier-url 'https://api-testnet.sonicscan.org/api' [CONTRACT_ADDRESS] FeeDistributorFactory
```

```bash
forge verify-contract --watch --verifier etherscan --etherscan-api-key [APY_KEY] --verifier-url 'https://api-testnet.sonicscan.org/api' --constructor-args [BUILD_ARGS] [CONTRACT_ADDRESS] LauncherPlugin
```

```bash
forge verify-contract --watch --verifier etherscan --etherscan-api-key [APY_KEY] --verifier-url 'https://api-testnet.sonicscan.org/api' --constructor-args [BUILD_ARGS] [CONTRACT_ADDRESS] Minter
```

```bash
forge verify-contract --watch --verifier etherscan --etherscan-api-key [APY_KEY] --verifier-url 'https://api-testnet.sonicscan.org/api' --constructor-args [BUILD_ARGS] [CONTRACT_ADDRESS] Router
```

```bash
forge verify-contract --watch --verifier etherscan --etherscan-api-key [APY_KEY] --verifier-url 'https://api-testnet.sonicscan.org/api' [CONTRACT_ADDRESS] VoteModule
```

```bash
forge verify-contract --watch --verifier etherscan --etherscan-api-key [APY_KEY] --verifier-url 'https://api-testnet.sonicscan.org/api' --constructor-args [BUILD_ARGS] [CONTRACT_ADDRESS] XShadow
```

```bash
forge verify-contract --watch --verifier etherscan --etherscan-api-key [APY_KEY] --verifier-url 'https://api-testnet.sonicscan.org/api' --libraries contracts/libraries/RewardClaimers.sol:RewardClaimers:[REWARDS_CLAIMER_ADDRESS] [CONTRACT_ADDRESS] Voter
```

```bash
forge verify-contract --watch --verifier etherscan --etherscan-api-key [APY_KEY] --verifier-url 'https://api-testnet.sonicscan.org/api' --constructor-args [BUILD_ARGS] [CONTRACT_ADDRESS] TimeLock
```

### Verify Contracts Sonic Mainnet

```bash
forge verify-contract --watch --verifier etherscan --etherscan-api-key [APY_KEY] --verifier-url 'https://api.sonicscan.org/api' [CONTRACT_ADDRESS] --constructor-args [BUILD_ARGS] contracts/AccessHub.sol:AccessHub
```

```bash
forge verify-contract --watch --verifier etherscan --etherscan-api-key [APY_KEY] --verifier-url 'https://api.sonicscan.org/api' [CONTRACT_ADDRESS] FeeDistributorFactory
```

```bash
forge verify-contract --watch --verifier etherscan --etherscan-api-key [APY_KEY] --verifier-url 'https://api.sonicscan.org/api' --constructor-args [BUILD_ARGS] [CONTRACT_ADDRESS] LauncherPlugin
```

```bash
forge verify-contract --watch --verifier etherscan --etherscan-api-key [APY_KEY] --verifier-url 'https://api.sonicscan.org/api' --constructor-args [BUILD_ARGS] [CONTRACT_ADDRESS] Minter
```

```bash
forge verify-contract --watch --verifier etherscan --etherscan-api-key [APY_KEY] --verifier-url 'https://api.sonicscan.org/api' --constructor-args [BUILD_ARGS] [CONTRACT_ADDRESS] Router
```

```bash
forge verify-contract --watch --verifier etherscan --etherscan-api-key [APY_KEY] --verifier-url 'https://api.sonicscan.org/api' [CONTRACT_ADDRESS] VoteModule
```

```bash
forge verify-contract --watch --verifier etherscan --etherscan-api-key [APY_KEY] --verifier-url 'https://api.sonicscan.org/api' --constructor-args [BUILD_ARGS] [CONTRACT_ADDRESS] XShadow
```

```bash
forge verify-contract --watch --verifier etherscan --etherscan-api-key [APY_KEY] --verifier-url 'https://api.sonicscan.org/api' --libraries contracts/libraries/RewardClaimers.sol:RewardClaimers:[REWARDS_CLAIMER_ADDRESS] [CONTRACT_ADDRESS] Voter
```

```bash
forge verify-contract --watch --verifier etherscan --etherscan-api-key [APY_KEY] --verifier-url 'https://api.sonicscan.org/api' --constructor-args [BUILD_ARGS] [CONTRACT_ADDRESS] TimeLock
```

---

## Constructor Args Helpers if you every want to verify the contracts

Use `cast abi-encode` to prepare constructor arguments. Replace addresses accordingly.

**For contracts with 5 arguments:**
```bash
cast abi-encode "constructor(address,address,address,address,address)" \
0x68684adFac7AC51b67ce9A9b5d1335B9247AA276 \
0x4Ada7f1F305B3b5FCf0225933De7539557D55104 \
0xe4878b1870518F5988572658000E7B905690D2aB \
0xc07317aFf4f9cd4f4Cf7785898902a31A46D4536 \
0x8B0e0702d3FbeA4aE39e11242b1200734dC76998
```

**For contracts with 4 arguments:**
```bash
cast abi-encode "constructor(address,address,address,address)" \
0x4Ada7f1F305B3b5FCf0225933De7539557D55104 \
0xe4878b1870518F5988572658000E7B905690D2aB \
0xc07317aFf4f9cd4f4Cf7785898902a31A46D4536 \
0x3D13F94BAD21Ca68f7691e84b0057Bcb7213Bc9A
```

**For contracts with 3 arguments:**
```bash
cast abi-encode "constructor(address,address,address)" \
0x4Ada7f1F305B3b5FCf0225933De7539557D55104 \
0xc07317aFf4f9cd4f4Cf7785898902a31A46D4536 \
0xe4878b1870518F5988572658000E7B905690D2aB
```

**For contracts with 2 arguments:**
```bash
cast abi-encode "constructor(address,address)" \
0xB61E0D2CC3Dd29b57AfA72045cf34BB8A39E984e \
0x039e2fB66102314Ce7b64Ce5Ce3E5183bc94aD38
```

**For contracts with 1 argument:**
```bash
cast abi-encode "constructor(address)" \
0xa2190F1372905dEce19777D20d2385A7533141e6
```

**For complex arguments (e.g. TimeLock):**
```bash
cast abi-encode "constructor(uint256,address[],address[],address)" \
864000 \
"[0xe4878b1870518F5988572658000E7B905690D2aB]" \
"[0xe4878b1870518F5988572658000E7B905690D2aB]" \
0xe4878b1870518F5988572658000E7B905690D2aB
```

---

### Additional Notes

- RewardClaimers is a library that is used to claim rewards from the pool.

### Deploy Full (Testnet)
```bash
forge script scripts/foundry/non-cl/DeployFull.sol:DeployFull \
--rpc-url $SONIC_RPC_TESTNET \
--private-key $PRIVATE_KEY \
--libraries contracts/libraries/RewardClaimers.sol:RewardClaimers:0x870462D78fa1a5C3D6bBb69bAaD72b97b5f3cB84 \
--chain-id 57054 \
--broadcast \
--verify \
--verifier-url $SONICSCAN_TESTNET_URL \
--verifier-api-key $SONICSCAN_TESTNET_API_KEY
```

---

### Deploy Full Non-CL (Sonic Mainnet)
```bash
forge script scripts/foundry/non-cl/DeployFull.sol:DeployFull \
--rpc-url $SONIC_RPC \
--private-key $PRIVATE_KEY \
--libraries contracts/libraries/RewardClaimers.sol:RewardClaimers:0x870462D78fa1a5C3D6bBb69bAaD72b97b5f3cB84 \
--chain-id 146 \
--broadcast \
--verify \
--verifier-url $SONICSCAN_URL \
--verifier-api-key $SONICSCAN_API_KEY
```
