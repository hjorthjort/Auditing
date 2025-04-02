// SPDX-License-Identifier: MIT
pragma solidity ^0.8.x;

import {Script} from "forge-std/Script.sol";
import {ScriptTools} from "./utils/ScriptTools.sol";

import {stdJson} from "forge-std/StdJson.sol";

import {FeeCollectorLibrary} from "./steps/01_FeeCollector.sol";
import {ClGaugeFactoryLibrary} from "./steps/02_ClGaugeFactory.sol";
import {FeeCollectorInstance} from "./instances/FeeCollectorInstance.sol";
import {ClGaugeFactoryInstance} from "./instances/ClGaugeFactoryInstance.sol";
import {console2} from "forge-std/console2.sol";

contract DeployGaugeBase is Script {
    using stdJson for string;
    using ScriptTools for string;

    struct DeployedContracts {
        address feeCollector;
        address clGaugeFactory;
    }

    function deploy(bool exportContracts) internal returns (DeployedContracts memory) {
        string memory targetChain = vm.envOr("TARGET_CHAIN", string("testnet"));
        // Load configuration
        string memory config = ScriptTools.readInput(targetChain);
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        // Step 1: Deploy FeeCollector
        console2.log("Deploying FeeCollector...");
        FeeCollectorInstance memory feeCollectorInstance =
            FeeCollectorLibrary.deploy(config.readAddress(".treasury"), config.readAddress(".voter"));
        console2.log("FeeCollector deployed at:", address(feeCollectorInstance.feeCollector));

        // Step 2: Deploy ClGaugeFactory
        console2.log("Deploying ClGaugeFactory...");
        ClGaugeFactoryInstance memory clGaugeFactoryInstance = ClGaugeFactoryLibrary.deploy(
            config.readAddress(".nfpManager"), config.readAddress(".voter"), address(feeCollectorInstance.feeCollector)
        );
        console2.log("ClGaugeFactory deployed at:", address(clGaugeFactoryInstance.clGaugeFactory));

        DeployedContracts memory contracts;
        contracts.feeCollector = address(feeCollectorInstance.feeCollector);
        contracts.clGaugeFactory = address(clGaugeFactoryInstance.clGaugeFactory);

        if (exportContracts) {
            ScriptTools.exportContract(targetChain, "feeCollector", address(feeCollectorInstance.feeCollector));
            ScriptTools.exportContract(targetChain, "clGaugeFactory", address(clGaugeFactoryInstance.clGaugeFactory));
        }

        return contracts;
    }
}
