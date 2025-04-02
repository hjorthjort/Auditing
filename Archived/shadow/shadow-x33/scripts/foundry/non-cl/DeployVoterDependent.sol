// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {DeployBase} from "./DeployBase.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {ScriptTools} from "./utils/ScriptTools.sol";

contract DeployVoterDependent is DeployBase {
    using stdJson for string;
    using ScriptTools for string;

    function run() external {
        string memory network = vm.envString("TARGET_CHAIN");

        string memory root = vm.projectRoot();
        string memory configPath = string.concat(root, "/scripts/foundry/non-cl/config/dependent.json");
        string memory json = vm.readFile(configPath);
        DeployedContracts memory deployedContracts;
        deployedContracts.timelock = json.readAddress(".timelock");
        deployedContracts.accessHub = json.readAddress(".accessHub");
        deployedContracts.voter = json.readAddress(".voter");
        deployedContracts.minter = json.readAddress(".minter");
        deployedContracts.shadow = json.readAddress(".shadow");
        deployedContracts.pairFactory = json.readAddress(".pairFactory");
        deployedContracts.gaugeFactory = json.readAddress(".gaugeFactory");
        deployedContracts.launcherPlugin = json.readAddress(".launcherPlugin");
        deployedContracts.feeRecipientFactory = json.readAddress(".feeRecipientFactory");
        deployedContracts.feeDistributorFactory = json.readAddress(".feeDistributorFactory");
        deployedContracts.voteModule = json.readAddress(".voteModule");
        deployedContracts.xShadow = json.readAddress(".xShadow");

        deployVoterDependentContracts(deployedContracts, true);
    }

    function deployForTest() internal returns (DeployedContracts memory) {
        DeployedContracts memory deployedContracts = deployVoterIndependentContracts(false, false);
        deployVoterDependentContracts(deployedContracts, false);
        return deployedContracts;
    }
}
