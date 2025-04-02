// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {AccessHub} from "contracts/AccessHub.sol";
import {TransparentUpgradeableProxy} from
    "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {ProxyAdmin} from
    "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {console2} from "forge-std/console2.sol";
import {IAccessHub} from "contracts/interfaces/IAccessHub.sol";

contract FirstDeployAccessHub is Script {
    address timelock = 0x4577D5d9687Ee4413Fc0c391b85861F0a383Df50;
    address treasury = 0x5Be2e859D0c2453C9aA062860cA27711ff553432;
    address voter = 0x0000000000000000000000000000000000000000;
    address minter = 0x0000000000000000000000000000000000000000;
    address launcherPlugin = 0x0000000000000000000000000000000000000000;
    address xShadow = 0x0000000000000000000000000000000000000000;
    address x33 = 0x0000000000000000000000000000000000000000;
    address shadowV3PoolFactory = 0x0000000000000000000000000000000000000000;
    address poolFactory = 0x0000000000000000000000000000000000000000;
    address clGaugeFactory = 0x0000000000000000000000000000000000000000;
    address gaugeFactory = 0x0000000000000000000000000000000000000000;
    address feeRecipientFactory = 0x0000000000000000000000000000000000000000;
    address feeDistributorFactory = 0x0000000000000000000000000000000000000000;
    address feeCollector = 0x0000000000000000000000000000000000000000;
    address voteModule = 0x0000000000000000000000000000000000000000;


    function run() external {
        vm.startBroadcast();
        // deploy implementation
        AccessHub accessHubImpl = new AccessHub();
        
        // encode initialize call with init params struct
        bytes memory initData = abi.encodeWithSelector(
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
        // deployer address
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        // deploy proxy
        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            address(accessHubImpl),  // logic
            deployer,                // owner
            initData                 // initializer call
        );

        // This is the storage slot where the admin address is stored in the proxy
        // From OZ TransparentUpgradeableProxy: bytes32(uint256(keccak256('eip1967.proxy.admin')) - 1)
        bytes32 ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;
        address actualAdmin = address(uint160(uint256(vm.load(address(proxy), ADMIN_SLOT))));

        vm.stopBroadcast();

        console2.log("Deployer:", deployer);
        console2.log("Proxy Admin:", actualAdmin);
        console2.log("AccessHub Impl:", address(accessHubImpl));
        console2.log("ProxyAccessHub:", address(proxy));
    }
}
