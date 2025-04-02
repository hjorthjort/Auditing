// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.x;

import '../../core/interfaces/IShadowV3Factory.sol';
import '../../core/interfaces/IShadowV3Pool.sol';
import '../../core/interfaces/IShadowV3PoolDeployer.sol';

import './PeripheryImmutableState.sol';
import '../interfaces/IPoolInitializer.sol';

/// @title Creates and initializes V3 Pools
abstract contract PoolInitializer is IPoolInitializer, PeripheryImmutableState {
    /// @inheritdoc IPoolInitializer
    function createAndInitializePoolIfNecessary(
        address token0,
        address token1,
        int24 tickSpacing,
        uint160 sqrtPriceX96
    ) external payable override returns (address pool) {
        require(token0 < token1);
        IShadowV3Factory factory = IShadowV3Factory(IShadowV3PoolDeployer(deployer).ShadowV3Factory());
        pool = factory.getPool(token0, token1, tickSpacing);

        if (pool == address(0)) {
            pool = factory.createPool(token0, token1, tickSpacing, sqrtPriceX96);
        } else {
            (uint160 sqrtPriceX96Existing, , , , , , ) = IShadowV3Pool(pool).slot0();
            if (sqrtPriceX96Existing == 0) {
                IShadowV3Pool(pool).initialize(sqrtPriceX96);
            }
        }
    }
}
