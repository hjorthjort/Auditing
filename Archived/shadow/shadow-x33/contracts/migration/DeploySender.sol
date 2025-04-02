// SPDX-License-Identifier: MIT
pragma solidity ^0.8.x;

import {Script} from "forge-std/Script.sol";
import {ShadowMessageSender} from "contracts/migration/ShadowMessageSender.sol";
import {console2} from "forge-std/console2.sol";

contract DeploySender is Script {
    address constant LZ_ENDPOINT = 0x1a44076050125825900e736c501f859c50fE728c;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        
        // deploy ShadowMessageSender
        ShadowMessageSender sender = new ShadowMessageSender(
            LZ_ENDPOINT,
            vm.addr(deployerPrivateKey)
        );
        
        console2.log("ShadowMessageSender:", address(sender));
        vm.stopBroadcast();
    }
} 