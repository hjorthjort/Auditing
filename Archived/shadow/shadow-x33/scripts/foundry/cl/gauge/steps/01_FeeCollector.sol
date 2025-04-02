// SPDX-License-Identifier: MIT
pragma solidity ^0.8.x;

import {FeeCollector} from "../../../../../contracts/CL/gauge/FeeCollector.sol";
import {FeeCollectorInstance} from "../instances/FeeCollectorInstance.sol";

library FeeCollectorLibrary {
    function deploy(address treasury, address voter) internal returns (FeeCollectorInstance memory) {
        FeeCollector feeCollector = new FeeCollector(treasury, voter);

        return FeeCollectorInstance({feeCollector: feeCollector, treasury: treasury, voter: voter});
    }
}
