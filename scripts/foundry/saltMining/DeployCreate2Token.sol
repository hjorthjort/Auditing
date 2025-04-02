// SPDX-License-Identifier: MIT
pragma solidity ^0.8.x;

import {Script} from "forge-std/Script.sol";
import {Shadow} from "contracts/Shadow.sol";
import {console2} from "forge-std/console2.sol";
import {XShadow} from "contracts/xShadow/XShadow.sol";
import {x33} from "contracts/xShadow/x33.sol";
import {Gems} from "contracts/Gems.sol";

contract DeployTokenCreate2 is Script {
    bytes32 constant SALT = 0x07712d748c40608810a0305751e35f0eedef70d2b96ac5751af4f870f5060050;
    address constant EXPECTED_ADDRESS = 0x5555b2733602DEd58D47b8D3D989E631CBee5555;

    function run() external {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));

        bytes memory initCode = abi.encodePacked(
            // contract bytecode
            type(Gems).creationCode,
            // shadow
            abi.encode(
                // address(0x5Be2e859D0c2453C9aA062860cA27711ff553432),  // operator
                address(0x5e7A9eea6988063A4dBb9CcDDB3E04C923E8E37f)  // accesshub
                // address(0x5050bc082FF4A74Fb6B0B04385dEfdDB114b2424),  // xshadow
                // address(0x3aF1dD7A2755201F8e2D6dCDA1a61d9f54838f4f),  // voter
                // address(0xDCB5A24ec708cc13cee12bFE6799A78a79b666b4)  // votemodule
            )
        );

        bytes32 initCodeHash = keccak256(initCode);
        console2.log("initCodeHash:", vm.toString(initCodeHash));

        address deployed;
        assembly {
            deployed := create2(0, add(initCode, 0x20), mload(initCode), SALT)
        }

        require(deployed != address(0), "Create2: Failed on deploy");
        require(deployed == EXPECTED_ADDRESS, "Create2: Expected address mismatch");
        console2.log("Deployed address:", deployed);

        vm.stopBroadcast();
    }
} 