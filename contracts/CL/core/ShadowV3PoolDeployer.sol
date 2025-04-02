// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.x;

import {IShadowV3PoolDeployer} from "./interfaces/IShadowV3PoolDeployer.sol";

import {ShadowV3Pool} from "./ShadowV3Pool.sol";
import {IShadowV3Factory} from "./interfaces/IShadowV3Factory.sol";

contract ShadowV3PoolDeployer is IShadowV3PoolDeployer {
    address public immutable ShadowV3Factory;

    constructor(address _shadowV3Factory) {
        ShadowV3Factory = _shadowV3Factory;
    }

    /// @dev Deploys a pool with the given parameters by transiently setting the parameters storage slot and then
    /// clearing it after deploying the pool.
    /// @param token0 The first token of the pool by address sort order
    /// @param token1 The second token of the pool by address sort order
    /// @param tickSpacing The tickSpacing of the pool
    function deploy(address token0, address token1, int24 tickSpacing) external returns (address pool) {
        require(msg.sender == ShadowV3Factory);
        pool = address(new ShadowV3Pool{salt: keccak256(abi.encode(token0, token1, tickSpacing))}());
    }

    function parameters()
        external
        view
        returns (address factory, address token0, address token1, uint24 fee, int24 tickSpacing)
    {
        (factory, token0, token1, fee, tickSpacing) = IShadowV3Factory(ShadowV3Factory).parameters();
    }

    function poolBytecode() external pure returns (bytes memory _bytecode) {
        _bytecode = type(ShadowV3Pool).creationCode;
    }
}
