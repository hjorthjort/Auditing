// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.x;

import {ShadowV3PoolDeployer} from "../../../../../contracts/CL/core/ShadowV3PoolDeployer.sol";

struct PoolDeployerInstance {
    ShadowV3PoolDeployer poolDeployer;
    address factory;
}
