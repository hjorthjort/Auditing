// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import {IShadowV3PoolImmutables} from "./pool/IShadowV3PoolImmutables.sol";
import {IShadowV3PoolState} from "./pool/IShadowV3PoolState.sol";
import {IShadowV3PoolDerivedState} from "./pool/IShadowV3PoolDerivedState.sol";
import {IShadowV3PoolActions} from "./pool/IShadowV3PoolActions.sol";
import {IShadowV3PoolOwnerActions} from "./pool/IShadowV3PoolOwnerActions.sol";
import {IShadowV3PoolErrors} from "./pool/IShadowV3PoolErrors.sol";
import {IShadowV3PoolEvents} from "./pool/IShadowV3PoolEvents.sol";

/// @title The interface for a Shadow V3 Pool
/// @notice A Shadow pool facilitates swapping and automated market making between any two assets that strictly conform
/// to the ERC20 specification
/// @dev The pool interface is broken up into many smaller pieces
interface IShadowV3Pool is
    IShadowV3PoolImmutables,
    IShadowV3PoolState,
    IShadowV3PoolDerivedState,
    IShadowV3PoolActions,
    IShadowV3PoolOwnerActions,
    IShadowV3PoolErrors,
    IShadowV3PoolEvents
{
    /// @notice if a new period, advance on interaction
    function _advancePeriod() external;

    /// @notice Get the index of the last period in the pool
    /// @return The index of the last period
    function lastPeriod() external view returns (uint256);
}
