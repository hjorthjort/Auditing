// SPDX-License-Identifier: MIT
pragma solidity ^0.8.x;

import {FeeCollector} from "../../../../../contracts/CL/gauge/FeeCollector.sol";

struct FeeCollectorInstance {
    FeeCollector feeCollector;
    address treasury;
    address voter;
}
