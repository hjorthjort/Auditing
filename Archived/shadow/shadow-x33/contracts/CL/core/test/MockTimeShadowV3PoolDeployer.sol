// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

import {IShadowV3PoolDeployer} from '../interfaces/IShadowV3PoolDeployer.sol';
import {MockTimeShadowV3Pool} from './MockTimeShadowV3Pool.sol';
import {IShadowV3Factory} from '../interfaces/IShadowV3Factory.sol';

contract MockTimeShadowV3PoolDeployer {
    //event PoolDeployed(address pool);

    address public immutable shadowV3Factory;

    constructor(address _shadowV3Factory) {
        shadowV3Factory = _shadowV3Factory;
    }

    function deploy(address token0, address token1, int24 tickSpacing) external returns (address pool) {
        pool = address(new MockTimeShadowV3Pool{salt: keccak256(abi.encodePacked(token0, token1, tickSpacing))}());
        //emit PoolDeployed(pool);
    }

    function parameters()
        external
        view
        returns (address factory, address token0, address token1, uint24 fee, int24 tickSpacing)
    {
        (factory, token0, token1, fee, tickSpacing) = IShadowV3Factory(shadowV3Factory).parameters();
    }
}
