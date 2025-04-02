# protocol
Kinode onchain protocol

### Setup

1. Clone repo
2. Install foundry + soldeer
3. `forge soldeer update`
4. `forge build`

### Kimap

Global onchain namespace for Kinode OS.

Kimap.sol is the main contract that manages the global namespace. It acts as a hierachical key-value store, with 3 kinds of keys:
- names, which are minted as ERC-721 tokens and have token-bound accounts associated with them
- data keys, which are mutable storage slots beneath a name
- fact keys, which are immutable storage slots beneath a name

Token-bound accounts may use various implementations of `ERC721TokenBoundMech.sol`. If a `gene` is set for a name in kimap, then any names minted *beneath* will use the same contract implementation for their token-bound accounts.

When kimap is deployed, a "root node" is minted. Names minted beneath the root node are called TLZs, or "top-level zones". These have similar characteristics to TLDs in DNS, but ultimately, are just names. Upon deployment, we mint the `.os` and `.kino` TLZs. Each of these have custom account implementations, currently `KinoAccount9CharCommitMinter.sol` and `KinoAccountPermissionedMinter.sol`, respectively.

Like other names with the default account implementation (`KinoAccount.sol`), the owner of the root node is the only address capable of minting names beneath it. This means that the owner of the root node is uniquely capable of creating new TLZs. At the time of initial deployment, the root node will be owned by the deployer of kimap, a multisig controlled by Sybil Technologies. We will use it to create and distribute TLZs to strategic partners. Later on, ownership will be transferred to a governance contract which will allow Kinode users to vote on the creation of new TLZs.

### Token-Bound Accounts

The `src/account` folder contains various account implementations for token-bound accounts:

#### Base Accounts
- `KinoAccount.sol` - Default account implementation. Contains core ERC-6551 functionality as defined by `ERC721TokenBoundMech.sol`.
- `KinoAccountMinterUpgradable.sol` - Base upgradeable account implementation that other "minter" accounts inherit from. Use this to create upgradable namespace TBAs that might allow addresses other than the TBA itself to mint names, notes, or facts beneath it.

#### Specialized Minters
- `KinoAccount9CharCommitMinter.sol` - Used for `.os` TLZ. Requires:
  - Names to be at least 9 characters
  - Inherits commitment functionality from `KinoAccountCommitMinter.sol`

- `KinoAccountCommitMinter.sol` - Implements:
  - A commitment scheme to prevent frontrunning

- `KinoAccountPermissionedMinter.sol` - Used for `.kino` TLZ. Implements:
  - Permissioned minting where users must be authorized
  - Owner can grant minting allowances to specific addresses

- `KinoAccountPaidMinter.sol` - Implements paid minting where:
  - Users must pay a configurable price to mint names
  - Owner can update pricing
  - Owner can withdraw accumulated funds

- `KinoAccountProxy.sol` - Used to create upgradable TBAs. `Kimap.sol` uses this proxy address to create counterfactual TBA addresses.
