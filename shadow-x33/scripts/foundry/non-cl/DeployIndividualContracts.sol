// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {DeployBase} from "./DeployBase.sol";

contract DeployIndividualContracts is DeployBase {
    function run() external {
        deployVoterIndependentContracts(false, true);
    }
}
