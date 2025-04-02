// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {QuoterV2Instance} from "../instances/QuoterV2Instance.sol";
import {QuoterV2} from "contracts/CL/periphery/lens/QuoterV2.sol";

library QuoterV2Library {
    function deploy(address deployer, address WETH9) internal returns (QuoterV2Instance memory) {
        // Deploy QuoterV2 contract
        QuoterV2 quoter = new QuoterV2(deployer, WETH9);
        return QuoterV2Instance({quoter: address(quoter), WETH9: WETH9, deployer: deployer});
    }
}
