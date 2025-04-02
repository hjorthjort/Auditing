// SPDX-License-Identifier: MIT
pragma solidity ^0.8.x;

import {Script} from "forge-std/Script.sol";
import {ShadowMessageRecipient} from "contracts/migration/ShadowMessageRecipient.sol";
import {console2} from "forge-std/console2.sol";

contract DeployReceiver is Script {
    address constant LZ_ENDPOINT = 0x6F475642a6e85809B1c36Fa62763669b1b48DD5B;

    function run() external {
        // fork rpc
        vm.createSelectFork("https://sonic-mainnet.g.alchemy.com/v2/S9R8DoBeLVVYRi4DPAcBJe8p0PnrQtbG");
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        // deploy ShadowMessageReceiver
        ShadowMessageRecipient receiver = new ShadowMessageRecipient(
            LZ_ENDPOINT,
            vm.addr(deployerPrivateKey)
        );

        console2.log("ShadowMessageReceiver:", address(receiver));
        vm.stopBroadcast();
    }
} 