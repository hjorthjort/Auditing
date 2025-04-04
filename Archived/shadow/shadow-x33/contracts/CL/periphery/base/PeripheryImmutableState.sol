// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.x;

import '../interfaces/IPeripheryImmutableState.sol';

/// @title Immutable state
/// @notice Immutable state used by periphery contracts
abstract contract PeripheryImmutableState is IPeripheryImmutableState {
    /// @inheritdoc IPeripheryImmutableState
    address public immutable override deployer;
    /// @inheritdoc IPeripheryImmutableState
    address public immutable override WETH9;

    constructor(address _deployer, address _WETH9) {
        deployer = _deployer;
        WETH9 = _WETH9;
    }
}
