// SPDX-License-Identifier: MIT
pragma solidity ^0.8.x;

import {PairFactory} from "../../../../contracts/factories/PairFactory.sol";
import {GaugeFactory} from "../../../../contracts/factories/GaugeFactory.sol";
import {FeeRecipientFactory} from "../../../../contracts/factories/FeeRecipientFactory.sol";
import {FeeDistributorFactory} from "../../../../contracts/factories/FeeDistributorFactory.sol";
import {FactoriesInstance} from "../instances/FactoriesInstance.sol";

library DeployFactoriesLibrary {
    function deploy(address voter, address treasury, address accessHub) internal returns (FactoriesInstance memory) {
        // Deploy FeeRecipientFactory first since PairFactory needs it
        FeeRecipientFactory feeRecipientFactory = new FeeRecipientFactory(treasury, voter, accessHub);

        // Deploy PairFactory
        PairFactory pairFactory = new PairFactory(voter, treasury, accessHub, address(feeRecipientFactory));

        // Deploy GaugeFactory
        GaugeFactory gaugeFactory = new GaugeFactory();

        // Deploy FeeDistributorFactory
        FeeDistributorFactory feeDistributorFactory = new FeeDistributorFactory();

        // Verify PairFactory addresses
        require(pairFactory.voter() == voter, "PairFactory: Invalid voter");
        require(pairFactory.treasury() == treasury, "PairFactory: Invalid treasury");
        require(pairFactory.accessHub() == accessHub, "PairFactory: Invalid accessHub");
        require(
            pairFactory.feeRecipientFactory() == address(feeRecipientFactory),
            "PairFactory: Invalid feeRecipientFactory"
        );

        // Verify FeeRecipientFactory addresses
        require(feeRecipientFactory.treasury() == treasury, "FeeRecipientFactory: Invalid treasury");
        require(feeRecipientFactory.voter() == voter, "FeeRecipientFactory: Invalid voter");
        require(feeRecipientFactory.accessHub() == accessHub, "FeeRecipientFactory: Invalid accessHub");

        return FactoriesInstance({
            voter: voter,
            feeRecipientFactory: address(feeRecipientFactory),
            gaugeFactory: address(gaugeFactory),
            feeDistributorFactory: address(feeDistributorFactory),
            pairFactory: address(pairFactory)
        });
    }
}
