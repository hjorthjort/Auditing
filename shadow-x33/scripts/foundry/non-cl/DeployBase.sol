// SPDX-License-Identifier: MIT
pragma solidity ^0.8.x;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";
import {ScriptTools} from "./utils/ScriptTools.sol";
import {VoterDeployLibrary} from "./steps/02_Voter.sol";
import {MinterDeployLibrary} from "./steps/03_Minter.sol";
import {ShadowTokenDeployLibrary} from "./steps/04_ShadowToken.sol";
import {xShadowDeployLibrary} from "./steps/09_xShadow.sol";
import {DeployFactoriesLibrary} from "./steps/05_Factories.sol";
import {DeployLauncherPluginLibrary} from "./steps/06_LauncherPlugin.sol";
import {DeployVoteModuleLibrary} from "./steps/08_VoteModule.sol";
import {DeployRouterLibrary} from "./steps/07_Router.sol";
import {AccessHubInstance} from "./instances/AccessHubInstance.sol";
import {VoterInstance} from "./instances/VoterInstance.sol";
import {MinterInstance} from "./instances/MinterInstance.sol";
import {ShadowTokenInstance} from "./instances/ShadowTokenInstance.sol";
import {xShadowInstance} from "./instances/xShadowTokenInstance.sol";
import {FactoriesInstance} from "./instances/FactoriesInstance.sol";
import {LauncherPluginInstance} from "./instances/LauncherPluginInstance.sol";
import {VoteModuleInstance} from "./instances/VoteModuleInstance.sol";
import {RouterInstance} from "./instances/RouterInstance.sol";
import {VoterSetInstance} from "./instances/VoterSetInstance.sol";
import {AccessHubSetInstance} from "./instances/AccessHubSetInstance.sol";
import {stdJson} from "forge-std/StdJson.sol";
    
contract DeployBase is Script {
    using stdJson for string;
    using ScriptTools for string;

    struct DeployedContracts {
        address timelock;
        address accessHub;
        address voter;
        address minter;
        address shadow;
        address pairFactory;
        address gaugeFactory;
        address launcherPlugin;
        address feeRecipientFactory;
        address feeDistributorFactory;
        address router;
        address voteModule;
        address xShadow;
    }

    function deployVoterIndependentContracts(bool customTimelock, bool exportContracts)
        internal
        returns (DeployedContracts memory)
    {
        string memory targetChain = vm.envOr("TARGET_CHAIN", string("testnet"));
        // Load configuration
        string memory config = ScriptTools.readInput(targetChain);
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        
        // Read addresses from config
        address timelock = config.readAddress(".timelock");
        address accessHub = config.readAddress(".accessHub");
        console2.log("Using existing Timelock at:", timelock);
        console2.log("Using existing AccessHub at:", accessHub);

        // Step 3: Deploy Voter
        console2.log("Deploying Voter...");
        VoterInstance memory voterInstance = VoterDeployLibrary.deploy(accessHub);
        console2.log("Voter deployed at:", voterInstance.voter);

        // Step 4: Deploy Minter
        console2.log("Deploying Minter...");
        MinterInstance memory minterInstance =
            MinterDeployLibrary.deploy(accessHub, config.readAddress(".operator"));
        console2.log("Minter deployed at:", minterInstance.minter);

        // Step 5: Deploy Shadow Token
        console2.log("Skipping deploying Shadow Token...");
        // console2.log("Deploying Shadow Token...");
        // ShadowTokenInstance memory shadowTokenInstance = ShadowTokenDeployLibrary.deploy(minterInstance.minter);
        // console2.log("Shadow Token deployed at:", shadowTokenInstance.shadow);

        // Step 6: Deploy Factories
        console2.log("Deploying Factories...");
        FactoriesInstance memory factoriesInstance = DeployFactoriesLibrary.deploy(
            voterInstance.voter, config.readAddress(".treasury"), accessHub
        );
        console2.log("PairFactory deployed at:", factoriesInstance.pairFactory);
        console2.log("GaugeFactory deployed at:", factoriesInstance.gaugeFactory);
        console2.log("FeeRecipientFactory deployed at:", factoriesInstance.feeRecipientFactory);
        console2.log("FeeDistributorFactory deployed at:", factoriesInstance.feeDistributorFactory);

        // Step 7: Deploy Launcher Plugin
        console2.log("Deploying Launcher Plugin...");
        LauncherPluginInstance memory launcherPluginInstance = DeployLauncherPluginLibrary.deploy(
            voterInstance.voter, accessHub, config.readAddress(".operator")
        );
        console2.log("Launcher Plugin deployed at:", launcherPluginInstance.launcherPlugin);

        // Export all deployed contract addresses
        if (exportContracts) {
            ScriptTools.exportContract(targetChain, "timelock", timelock);
            ScriptTools.exportContract(targetChain, "accessHub", accessHub);
            ScriptTools.exportContract(targetChain, "voter", voterInstance.voter);
            ScriptTools.exportContract(targetChain, "minter", minterInstance.minter);
            // ScriptTools.exportContract(targetChain, "shadow", shadowTokenInstance.shadow);
            ScriptTools.exportContract(targetChain, "pairFactory", factoriesInstance.pairFactory);
            ScriptTools.exportContract(targetChain, "gaugeFactory", factoriesInstance.gaugeFactory);
            ScriptTools.exportContract(targetChain, "feeRecipientFactory", factoriesInstance.feeRecipientFactory);
            ScriptTools.exportContract(targetChain, "feeDistributorFactory", factoriesInstance.feeDistributorFactory);
            ScriptTools.exportContract(targetChain, "launcherPlugin", launcherPluginInstance.launcherPlugin);
        }

        DeployedContracts memory deployedContracts = DeployedContracts({
            timelock: timelock,
            accessHub: accessHub,
            voter: voterInstance.voter,
            minter: minterInstance.minter,
            shadow: address(0),
            pairFactory: factoriesInstance.pairFactory,
            gaugeFactory: factoriesInstance.gaugeFactory,
            launcherPlugin: launcherPluginInstance.launcherPlugin,
            feeRecipientFactory: factoriesInstance.feeRecipientFactory,
            feeDistributorFactory: factoriesInstance.feeDistributorFactory,
            router: address(0),
            voteModule: address(0),
            xShadow: address(0)
        });
        vm.stopBroadcast();
        return deployedContracts;
    }

    function deployVoterDependentContracts(DeployedContracts memory deployedContracts, bool exportContracts)
        internal
        returns (DeployedContracts memory)
    {
        string memory root = vm.projectRoot();
        string memory dependentPath = string.concat(root, "/scripts/foundry/non-cl/config/dependent.json");
        string memory dependent = vm.readFile(dependentPath);
        
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));

        // Step 8: Deploy Router
        console2.log("Deploying Router...");
        RouterInstance memory routerInstance =
            DeployRouterLibrary.deploy(deployedContracts.pairFactory, dependent.readAddress(".weth"));
        console2.log("Router deployed at:", routerInstance.router);

        // Step 9: Deploy Vote Module
        console2.log("Using existing Vote Module...");
        // console2.log("Deploying Vote Module...");
        // VoteModuleInstance memory voteModuleInstance = DeployVoteModuleLibrary.deploy();
        // console2.log("Vote Module deployed at:", voteModuleInstance.voteModule);

        // Step 10: Deploy xShadow
        console2.log("Using existing xShadow...");
        // console2.log("Deploying xShadow...");
        // xShadowInstance memory xShadowInstanceParam = xShadowDeployLibrary.deploy(
        //     config.readAddress(".shadow"),
        //     deployedContracts.voter,
        //     config.readAddress(".operator"),
        //     deployedContracts.accessHub,
        //     voteModuleInstance.voteModule,
        //     deployedContracts.minter
        // );
        // console2.log("xShadow deployed at:", xShadowInstanceParam.xShadow);

        // Initialize contracts and set up relationships
        console2.log("Initializing contracts...");

        // Initialize Voter
        console2.log("Skipping initializing Voter...");
        // VoterDeployLibrary.initialize(
        //     deployedContracts.voter,
        //     VoterSetInstance({
        //         shadow: deployedContracts.shadow,
        //         legacyFactory: deployedContracts.pairFactory,
        //         gauges: deployedContracts.gaugeFactory,
        //         feeDistributorFactory: deployedContracts.feeDistributorFactory,
        //         minter: deployedContracts.minter,
        //         msig: dependent.readAddress(".msig"),
        //         xShadow: deployedContracts.xShadow,
        //         clFactory: dependent.readAddress(".clFactory"),
        //         clGaugeFactory: dependent.readAddress(".clGaugeFactory"),
        //         nfpManager: dependent.readAddress(".nfpManager"),
        //         feeRecipientFactory: deployedContracts.feeRecipientFactory,
        //         voteModule: deployedContracts.voteModule,
        //         launcherPlugin: deployedContracts.launcherPlugin
        //     })
        // );

        // Initialize Vote Module
        console2.log("Initializing Vote Module...");
        DeployVoteModuleLibrary.initialize(
            deployedContracts.voteModule,
            deployedContracts.xShadow,
            deployedContracts.voter,
            deployedContracts.accessHub
        );

        vm.stopBroadcast();



        deployedContracts.router = routerInstance.router;
        return deployedContracts;
    }
}
