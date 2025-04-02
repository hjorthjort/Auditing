// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {DeployGaugeBase} from "./DeployGaugeBase.sol";

contract DeployGaugeFull is DeployGaugeBase {
    function run() external {
        DeployedContracts memory deployedContracts = deploy(true);
    }

    function deployForTest() internal returns (DeployedContracts memory) {
        DeployedContracts memory deployedContracts = deploy(false);
        return deployedContracts;
    }
}
