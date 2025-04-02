// SPDX-License-Identifier: MIT
pragma solidity ^0.8.x;

import {AccessHub, IAccessHub} from "../../../../contracts/AccessHub.sol";
import {AccessHubInstance} from "../instances/AccessHubInstance.sol";
import {AccessHubSetInstance} from "../instances/AccessHubSetInstance.sol";
import {X33DeployLibrary} from "./X33.s.sol";

library AccessHubDeployLibrary {
    function deploy(address timelock, address treasury) internal returns (AccessHubInstance memory) {
        AccessHub accessHub = new AccessHub();
        
        return AccessHubInstance({timelock: timelock, treasury: treasury, accessHub: address(accessHub)});
    }

    function set(address accessHub, AccessHubSetInstance memory setInstance) internal {
        // Create InitParams struct
        IAccessHub.InitParams memory params = IAccessHub.InitParams({
            timelock: setInstance.timelock,
            treasury: setInstance.treasury,
            voter: setInstance.voter,
            minter: setInstance.minter,
            launcherPlugin: setInstance.launcherPlugin,
            xShadow: setInstance.xShadow,
            x33: setInstance.x33,
            shadowV3PoolFactory: setInstance.shadowV3PoolFactory,
            poolFactory: setInstance.poolFactory,
            clGaugeFactory: setInstance.clGaugeFactory,
            gaugeFactory: setInstance.gaugeFactory,
            feeRecipientFactory: setInstance.feeRecipientFactory,
            feeDistributorFactory: setInstance.feeDistributorFactory,
            feeCollector: setInstance.feeCollector,
            voteModule: setInstance.voteModule
        });

        AccessHub(accessHub).initialize(params);
    }
}
