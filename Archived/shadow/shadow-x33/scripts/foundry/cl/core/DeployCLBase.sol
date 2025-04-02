// SPDX-License-Identifier: MIT
pragma solidity ^0.8.x;

import {Script} from "forge-std/Script.sol";
import {ScriptTools} from "./utils/ScriptTools.sol";
import {FactoryScript} from "./steps/01_Factory.sol";
import {FactoryInstance} from "./instances/FactoryInstance.sol";
import {PoolDeployerInstance} from "./instances/PoolDeployerInstance.sol";
import {PoolDeployerLib} from "./steps/02_PoolDeployer.sol";

import {stdJson} from "forge-std/StdJson.sol";

contract DeployCLBase is Script {
    using stdJson for string;
    using ScriptTools for string;

    struct DeployedContracts {
        address factory;
        address poolDeployer;
    }

    function deployContracts(bool exportContracts) internal returns (DeployedContracts memory) {
        string memory targetChain = vm.envOr("TARGET_CHAIN", string("mainnet"));
        string memory config = ScriptTools.readInput(targetChain);
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        FactoryInstance memory factoryInstance = FactoryScript.deploy(config.readAddress(".accessHub"));
        PoolDeployerInstance memory poolDeployerInstance = PoolDeployerLib.deploy(address(factoryInstance.factory));
        vm.stopBroadcast();

        DeployedContracts memory deployedContracts = DeployedContracts({
            factory: address(factoryInstance.factory),
            poolDeployer: address(poolDeployerInstance.poolDeployer)
        });

        if (exportContracts) {
            ScriptTools.exportContract(targetChain, "factory", address(factoryInstance.factory));
            ScriptTools.exportContract(targetChain, "poolDeployer", address(poolDeployerInstance.poolDeployer));
        }

        return deployedContracts;
    }
}
