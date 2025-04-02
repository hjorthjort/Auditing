// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {Quoter} from "contracts/CL/periphery/lens/Quoter.sol";
import {QuoterInstance} from "../instances/QuoterInstance.sol";

library QuoterLibrary {
    function deploy(address deployer, address WETH9) internal returns (QuoterInstance memory) {
        // Deploy Quoter contract
        Quoter quoter = new Quoter(deployer, WETH9);
        return QuoterInstance({quoter: address(quoter), WETH9: WETH9, deployer: deployer});
    }
}
