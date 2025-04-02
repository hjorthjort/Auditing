// SPDX-License-Identifier: MIT
pragma solidity ^0.8.x;

import {Shadow} from "../../../../contracts/Shadow.sol";
import {ShadowTokenInstance} from "../instances/ShadowTokenInstance.sol";

library ShadowTokenDeployLibrary {
    function deploy(address minter) internal returns (ShadowTokenInstance memory) {
        Shadow shadowToken = new Shadow(minter);

        require(shadowToken.minter() == minter, "Minter mismatch");

        return ShadowTokenInstance({minter: minter, shadow: address(shadowToken)});
    }
}
