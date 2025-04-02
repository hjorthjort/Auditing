// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {AccessHub} from "contracts/AccessHub.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {ITransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";
import {console2} from "forge-std/console2.sol";
import {IAccessHub} from "contracts/interfaces/IAccessHub.sol";

contract DirectAccessHubUpgrade is Script {
    address constant PROXY = 0x23F702ee76e447B7c9EeA928d3F8B44b81Da2fD9;
    address constant timelock = 0x4577D5d9687Ee4413Fc0c391b85861F0a383Df50;
    address constant treasury = 0x5Be2e859D0c2453C9aA062860cA27711ff553432;
    address constant voter = 0x0000000000000000000000000000000000000000;
    address constant minter = 0x0000000000000000000000000000000000000000;
    address constant launcherPlugin = 0x0000000000000000000000000000000000000000;
    address constant xShadow = 0x0000000000000000000000000000000000000000;
    address constant x33 = 0x0000000000000000000000000000000000000000;
    address constant shadowV3PoolFactory = 0xb2453885176Bf8895C5F2b084138256aA3886E87;
    address constant poolFactory = 0x0000000000000000000000000000000000000000;
    address constant clGaugeFactory = 0x0000000000000000000000000000000000000000;
    address constant gaugeFactory = 0x0000000000000000000000000000000000000000;
    address constant feeRecipientFactory = 0x0000000000000000000000000000000000000000;
    address constant feeDistributorFactory = 0x0000000000000000000000000000000000000000;
    address constant feeCollector = 0x0000000000000000000000000000000000000000;
    address constant voteModule = 0x0000000000000000000000000000000000000000;

    // This is the storage slot where the admin address is stored in the proxy
    // From OZ TransparentUpgradeableProxy: bytes32(uint256(keccak256('eip1967.proxy.admin')) - 1)
    bytes32 constant ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    function run() external {
        // Read the actual admin address from storage
        address proxyAdmin = address(uint160(uint256(vm.load(PROXY, ADMIN_SLOT))));
        vm.startBroadcast();
        // 1. deploy new impl with deployer eoa
        AccessHub newImplementation = new AccessHub();
        console2.log("New implementation:", address(newImplementation));

        // 2. encode the initialization call with all parameters
        bytes memory initCall = abi.encodeWithSelector(
            AccessHub.initialize.selector,
            IAccessHub.InitParams({
                timelock: timelock,
                treasury: treasury,
                voter: voter,
                minter: minter,
                launcherPlugin: launcherPlugin,
                xShadow: xShadow,
                x33: x33,
                shadowV3PoolFactory: shadowV3PoolFactory,
                poolFactory: poolFactory,
                clGaugeFactory: clGaugeFactory,
                gaugeFactory: gaugeFactory,
                feeRecipientFactory: feeRecipientFactory,
                feeDistributorFactory: feeDistributorFactory,
                feeCollector: feeCollector,
                voteModule: voteModule
            })
        );

        // 3. directly call upgradeAndCall on the ProxyAdmin
        ProxyAdmin(proxyAdmin).upgradeAndCall(
            ITransparentUpgradeableProxy(PROXY),
            address(newImplementation),
            initCall
        );

        console2.log("Upgrade completed successfully");
        vm.stopBroadcast();
    }
} 