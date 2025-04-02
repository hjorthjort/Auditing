// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.x;

import {ShadowV3Factory} from "contracts/CL/core/ShadowV3Factory.sol";
import {FactoryInstance} from "../instances/FactoryInstance.sol";

library FactoryScript {
    function deploy(address accessHub) internal returns (FactoryInstance memory) {
        // Deploy the factory contract
        ShadowV3Factory factory = new ShadowV3Factory(accessHub);
        FactoryInstance memory instance = FactoryInstance({factory: factory, accessHub: accessHub});
        // Verify initial tick spacings and fees
        require(factory.tickSpacingInitialFee(1) == 100, "Invalid 1bps setup");
        require(factory.tickSpacingInitialFee(5) == 250, "Invalid 5bps setup");
        require(factory.tickSpacingInitialFee(10) == 500, "Invalid 10bps setup");
        require(factory.tickSpacingInitialFee(50) == 3000, "Invalid 50bps setup");
        require(factory.tickSpacingInitialFee(100) == 10000, "Invalid 100bps setup");
        require(factory.tickSpacingInitialFee(200) == 20000, "Invalid 200bps setup");

        // Verify initial fee protocol
        require(factory.feeProtocol() == 5, "Invalid fee protocol");
        return instance;
    }

    function initializePoolDeployer(ShadowV3Factory factory, address poolDeployer) internal {
        factory.initialize(poolDeployer);
    }
}
