// SPDX-License-Identifier: MIT
pragma solidity ^0.8.x;

import {ClGaugeFactory} from "../../../../../contracts/CL/gauge/ClGaugeFactory.sol";

struct ClGaugeFactoryInstance {
    ClGaugeFactory clGaugeFactory;
    address nfpManager;
    address voter;
    address feeCollector;
}
