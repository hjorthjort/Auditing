// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {TickLens} from "contracts/CL/periphery/lens/TickLens.sol";
import {TickLensInstance} from "../instances/TickLensInstance.sol";

library TickLensLibrary {
    function deploy() internal returns (TickLensInstance memory) {
        TickLens tickLens = new TickLens();
        return TickLensInstance({tickLens: address(tickLens)});
    }
}
