// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {UniversalRouter} from "contracts/CL/universalRouter/UniversalRouter.sol";
import {IUniversalRouter} from "contracts/CL/universalRouter/interfaces/IUniversalRouter.sol";
import {RouterParameters} from "contracts/CL/universalRouter/base/RouterImmutables.sol";
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {Commands} from "contracts/CL/universalRouter/libraries/Commands.sol";

contract TestUniversalRouter is Test {
    UniversalRouter public router;
    address constant WS = 0x039e2fB66102314Ce7b64Ce5Ce3E5183bc94aD38;
    address constant GOGGLZ = 0x9fDbC3f8Abc05Fa8f3Ad3C17D2F806c1230c4564;
    
    function setUp() public {
        // Deploy UniversalRouter with same parameters as in your deploy script
        router = new UniversalRouter(RouterParameters(
            address(0x000000000022D473030F116dDEE9F6B43aC78BA3), // permit2
            WS, // WETH9
            address(0),
            address(0),
            address(0),
            address(0),
            address(0),
            address(0),
            address(0),
            address(0),
            address(0),
            address(0),
            address(0),
            address(0),
            address(0),
            address(0),
            address(0), // v2 factory
            address(0xed55Fa4772cBb9f45EA8118A39CF640df2fDB2dc), // v3 factory
            bytes32(0), // v2 init code hash
            bytes32(0x45abd56e0874f11d842a55bc9bba133f39d9d0489dc6d4577701e8f47faf7151) // v3 init code hash
        ));
    }

    function test_v3SwapExactInput() public {
        address ocho = makeAddr('ocho');
        vm.startPrank(ocho);
        deal(GOGGLZ, ocho, 1_000 ether);
        IERC20(GOGGLZ).approve(address(router), type(uint256).max);

        // encode path
        bytes memory path = abi.encodePacked(
            GOGGLZ,
            int24(50),
            WS
        );
        // build commands - now as bytes
        bytes memory commands = new bytes(1);
        commands[0] = bytes1(uint8(Commands.V3_SWAP_EXACT_IN));
        // build swap inputs
        bytes[] memory inputs = new bytes[](1);
        inputs[0] = abi.encode(
            ocho, // recipient
            100 ether, // amount in
            0, // amount out min
            path, // path
            true // payerIsUser = false, meaning router will pay
        );
        // execute the swap with a deadline

        // transfer ws to the router
        IUniversalRouter(address(router)).execute(commands, inputs, block.timestamp);

        // Log results
        console.log("ocho balance after swap:", IERC20(WS).balanceOf(ocho));
        
        vm.stopPrank();
    }
}
