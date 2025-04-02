// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.x;

import {ShadowV3PoolDeployer} from "../../../../../contracts/CL/core/ShadowV3PoolDeployer.sol";
import {PoolDeployerInstance} from "../instances/PoolDeployerInstance.sol";
import {IShadowV3Factory} from "../../../../../contracts/CL/core/ShadowV3Factory.sol";

library PoolDeployerLib {
    function deploy(address factory) internal returns (PoolDeployerInstance memory) {
        // Deploy the pool deployer with the factory address
        ShadowV3PoolDeployer poolDeployer = new ShadowV3PoolDeployer(factory);

        // Initialize the factory with the pool deployer address
        IShadowV3Factory(factory).initialize(address(poolDeployer));

        // Return the address of the deployed pool deployer
        return PoolDeployerInstance({poolDeployer: poolDeployer, factory: factory});
    }
}
