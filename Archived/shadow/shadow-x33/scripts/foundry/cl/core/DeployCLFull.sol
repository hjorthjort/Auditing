// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {DeployCLBase} from "./DeployCLBase.sol";

contract DeployCLFull is DeployCLBase {
    function run() external {
        deployContracts(true);
    }

    function deployForTest() internal returns (DeployedContracts memory) {
        DeployedContracts memory deployedContracts = deployContracts(false);
        return deployedContracts;
    }
}
