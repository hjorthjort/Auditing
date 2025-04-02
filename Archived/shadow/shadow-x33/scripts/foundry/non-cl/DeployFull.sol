// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {DeployBase} from "./DeployBase.sol";

contract DeployFull is DeployBase {
    function run() external {
        DeployedContracts memory deployedContracts = deployVoterIndependentContracts(true, true);

        deployVoterDependentContracts(deployedContracts, true);
    }

    function deployForTest() internal returns (DeployedContracts memory) {
        DeployedContracts memory deployedContracts = deployVoterIndependentContracts(false, false);
        deployVoterDependentContracts(deployedContracts, false);
        return deployedContracts;
    }
}
