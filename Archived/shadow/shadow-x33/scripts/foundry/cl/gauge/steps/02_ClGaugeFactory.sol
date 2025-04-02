// SPDX-License-Identifier: MIT
pragma solidity ^0.8.x;

import {ClGaugeFactory} from "../../../../../contracts/CL/gauge/ClGaugeFactory.sol";
import {ClGaugeFactoryInstance} from "../instances/ClGaugeFactoryInstance.sol";

library ClGaugeFactoryLibrary {
    function deploy(address nfpManager, address voter, address feeCollector)
        internal
        returns (ClGaugeFactoryInstance memory)
    {
        ClGaugeFactory gaugeFactory = new ClGaugeFactory(nfpManager, voter, feeCollector);

        return ClGaugeFactoryInstance({
            clGaugeFactory: gaugeFactory,
            nfpManager: nfpManager,
            voter: voter,
            feeCollector: feeCollector
        });
    }
}
