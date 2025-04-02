// SPDX-License-Identifier: MIT
pragma solidity ^0.8.x;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";
import {Shadow} from "contracts/Shadow.sol";
import {XShadow} from "contracts/xShadow/XShadow.sol";
import {x33} from "contracts/xShadow/x33.sol";
import {Gems} from "contracts/Gems.sol";

contract GetInitCode is Script {

    function run() public {
        // get the creation code (bytecode + constructor args)
        bytes memory creationCode = abi.encodePacked(
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
 
        bytes32 initCodeHash = keccak256(creationCode);
        
        console2.log("Init Code Hash:");
        console2.logBytes32(initCodeHash);
    }
}

