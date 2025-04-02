// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {DeployPeripheryBase} from "./DeployPeripheryBase.sol";

contract DeployPeripheryFull is DeployPeripheryBase {
    function run() external {
        deployContracts(true);
    }

    function deployForTest() internal returns (DeployedContracts memory) {
        DeployedContracts memory deployedContracts = deployContracts(false);
        return deployedContracts;
    }
}
