// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.x;
pragma abicoder v2;

import {PoolStorage} from './PoolStorage.sol';
import {TransferHelper} from './TransferHelper.sol';
import {IShadowV3Factory} from '../interfaces/IShadowV3Factory.sol';

library ProtocolActions {
    error NOT_AUTHORIZED();
    error INVALID_FEE();

    /// @notice Emitted when the protocol fee is changed by the pool
    /// @param feeProtocolOld The previous value of the token0 protocol fee
    /// @param feeProtocolNew The updated value of the token1 protocol fee
    event SetFeeProtocol(uint8 feeProtocolOld, uint8 feeProtocolNew);

    /// @notice Emitted when the collected protocol fees are withdrawn by the fee collector
    /// @param sender The address that collects the protocol fees
    /// @param recipient The address that receives the collected protocol fees
    /// @param amount0 The amount of token0 protocol fees that is withdrawn
    /// @param amount0 The amount of token1 protocol fees that is withdrawn
    event CollectProtocol(address indexed sender, address indexed recipient, uint128 amount0, uint128 amount1);

    event FeeAdjustment(uint24 oldFee, uint24 newFee);

    /// @notice Set % share of the fees that do not go to liquidity providers
    /// @dev Fetches from factory directly
    function setFeeProtocol(address factory) external {
        PoolStorage.PoolState storage $ = PoolStorage.getStorage();
        /// @dev fetch "old" feeProtocol from storage slot0
        uint8 feeProtocolOld = $.slot0.feeProtocol;
        /// @dev fetch "new" feeProtocol from factory mapping
        uint8 feeProtocol = IShadowV3Factory(factory).poolFeeProtocol(address(this));
        /// @dev if the two values are not the same, the factory mapping takes precedent
        if (feeProtocol != feeProtocolOld) {
            /// @dev set the storage feeProtocol to the factory's
            $.slot0.feeProtocol = feeProtocol;
            emit SetFeeProtocol(feeProtocolOld, feeProtocol);
        }
    }

    /// @notice Collect the protocol fee accrued to the pool
    /// @param recipient The address to which collected protocol fees should be sent
    /// @param amount0Requested The maximum amount of token0 to send, can be 0 to collect fees in only token1
    /// @param amount1Requested The maximum amount of token1 to send, can be 0 to collect fees in only token0
    /// @return amount0 The protocol fee collected in token0
    /// @return amount1 The protocol fee collected in token1
    function collectProtocol(
        address recipient,
        uint128 amount0Requested,
        uint128 amount1Requested,
        address token0,
        address token1
    ) external returns (uint128 amount0, uint128 amount1) {
        PoolStorage.PoolState storage $ = PoolStorage.getStorage();

        amount0 = amount0Requested > $.protocolFees.token0 ? $.protocolFees.token0 : amount0Requested;
        amount1 = amount1Requested > $.protocolFees.token1 ? $.protocolFees.token1 : amount1Requested;

        unchecked {
            if (amount0 > 0) {
                if (amount0 == $.protocolFees.token0) amount0--; /// @dev ensure that the slot is not cleared, for gas savings
                $.protocolFees.token0 -= amount0;
                TransferHelper.safeTransfer(token0, recipient, amount0);
            }
            if (amount1 > 0) {
                if (amount1 == $.protocolFees.token1) amount1--; /// @dev ensure that the slot is not cleared, for gas savings
                $.protocolFees.token1 -= amount1;
                TransferHelper.safeTransfer(token1, recipient, amount1);
            }
        }
        emit CollectProtocol(msg.sender, recipient, amount0, amount1);
    }

    function setFee(uint24 _fee, address factory) external {
        PoolStorage.PoolState storage $ = PoolStorage.getStorage();
        if (msg.sender != factory) revert NOT_AUTHORIZED();
        if (_fee > 100000) revert INVALID_FEE();
        uint24 _oldFee = $.fee;
        $.fee = _fee;
        emit FeeAdjustment(_oldFee, _fee);
    }
}
