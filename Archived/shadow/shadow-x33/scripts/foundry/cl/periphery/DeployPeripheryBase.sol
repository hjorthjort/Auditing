// SPDX-License-Identifier: MIT
pragma solidity ^0.8.x;

import {Script} from "forge-std/Script.sol";
import {ScriptTools} from "./utils/ScriptTools.sol";
import {SwapRouterLibrary} from "./steps/03_SwapRouter.sol";
import {SwapRouterInstance} from "./instances/SwapRouterInstance.sol";
import {NonfungiblePositionManagerLibrary} from "./steps/02_NonfungiblePositionManager.sol";
import {NonfungibleTokenPositionDescriptorLibrary} from "./steps/01_NonfungibleTokenPositionDescriptor.sol";
import {NonfungiblePositionManagerInstance} from "./instances/NonfungiblePositionManagerInstance.sol";
import {NonfungibleTokenPositionDescriptorInstance} from "./instances/NonfungibleTokenPositionDescriptorInstance.sol";
import {QuoterLibrary} from "./steps/04_Quoter.sol";
import {QuoterInstance} from "./instances/QuoterInstance.sol";
import {QuoterV2Library} from "./steps/05_QuoterV2.sol";
import {QuoterV2Instance} from "./instances/QuoterV2Instance.sol";
import {TickLensLibrary} from "./steps/06_TickLens.sol";
import {TickLensInstance} from "./instances/TickLensInstance.sol";
import {UniswapInterfaceMulticallLibrary} from "./steps/07_UniswapInterfaceMulticall.sol";
import {UniswapInterfaceMulticallInstance} from "./instances/UniswapInterfaceMulticallInstance.sol";

import {stdJson} from "forge-std/StdJson.sol";

contract DeployPeripheryBase is Script {
    using stdJson for string;
    using ScriptTools for string;

    struct DeployedContracts {
        address swapRouter;
        address nonfungiblePositionManager;
        address nonfungibleTokenPositionDescriptor;
        address quoter;
        address quoterV2;
        address tickLens;
        address uniswapInterfaceMulticall;
    }

    function deployContracts(bool exportContracts) internal returns (DeployedContracts memory) {
        string memory targetChain = vm.envOr("TARGET_CHAIN", string("testnet"));
        string memory config = ScriptTools.readInput(targetChain);

        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));

        // Deploy NonfungibleTokenPositionDescriptor first
        NonfungibleTokenPositionDescriptorInstance memory descriptorInstance =
            NonfungibleTokenPositionDescriptorLibrary.deploy(config.readAddress(".weth9"));

        // Deploy NonfungiblePositionManager
        NonfungiblePositionManagerInstance memory nonfungiblePositionManagerInstance = NonfungiblePositionManagerLibrary
            .deploy(
            config.readAddress(".deployer"),
            config.readAddress(".weth9"),
            address(descriptorInstance.descriptor),
            config.readAddress(".accessHub")
        );

        // Deploy SwapRouter
        SwapRouterInstance memory swapRouterInstance =
            SwapRouterLibrary.deploy(config.readAddress(".deployer"), config.readAddress(".weth9"));

        // Deploy Quoter
        QuoterInstance memory quoterInstance =
            QuoterLibrary.deploy(config.readAddress(".deployer"), config.readAddress(".weth9"));

        // Deploy QuoterV2
        QuoterV2Instance memory quoterV2Instance =
            QuoterV2Library.deploy(config.readAddress(".deployer"), config.readAddress(".weth9"));

        // Deploy TickLens
        TickLensInstance memory tickLensInstance = TickLensLibrary.deploy();

        // Deploy UniswapInterfaceMulticall
        UniswapInterfaceMulticallInstance memory uniswapInterfaceMulticallInstance =
            UniswapInterfaceMulticallLibrary.deploy();

        vm.stopBroadcast();

        DeployedContracts memory deployedContracts = DeployedContracts({
            swapRouter: address(swapRouterInstance.swapRouter),
            nonfungiblePositionManager: address(nonfungiblePositionManagerInstance.positionManager),
            nonfungibleTokenPositionDescriptor: address(descriptorInstance.descriptor),
            quoter: address(quoterInstance.quoter),
            quoterV2: address(quoterV2Instance.quoter),
            tickLens: address(tickLensInstance.tickLens),
            uniswapInterfaceMulticall: address(uniswapInterfaceMulticallInstance.uniswapInterfaceMulticall)
        });

        if (exportContracts) {
            ScriptTools.exportContract(targetChain, "swapRouter", address(swapRouterInstance.swapRouter));
            ScriptTools.exportContract(
                targetChain, "nonfungiblePositionManager", address(nonfungiblePositionManagerInstance.positionManager)
            );
            ScriptTools.exportContract(
                targetChain, "nonfungibleTokenPositionDescriptor", address(descriptorInstance.descriptor)
            );
            ScriptTools.exportContract(targetChain, "quoter", address(quoterInstance.quoter));
            ScriptTools.exportContract(targetChain, "quoterV2", address(quoterV2Instance.quoter));
            ScriptTools.exportContract(targetChain, "tickLens", address(tickLensInstance.tickLens));
        }

        return deployedContracts;
    }
}
