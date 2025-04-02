// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {QuoterV2} from "contracts/CL/periphery/lens/QuoterV2.sol";
import {IQuoterV2} from "contracts/CL/periphery/interfaces/IQuoterV2.sol";

contract QuoterV2Test is Test {
    QuoterV2 public quoter;
    address WS = 0x039e2fB66102314Ce7b64Ce5Ce3E5183bc94aD38;
    address GOGGLZ = 0x9fDbC3f8Abc05Fa8f3Ad3C17D2F806c1230c4564;
    address QUOTERV2 = 0x219b7ADebc0935a3eC889a148c6924D51A07535A;
    int24 constant TICK_SPACING = 100;

    function setUp() public {

    }

    function test_quoteExactInputSingle() public {
        (uint256 amountOut, 
         uint160 sqrtPriceX96After,
         uint32 initializedTicksCrossed,
         uint256 gasEstimate) = IQuoterV2(QUOTERV2).quoteExactInputSingle(
            IQuoterV2.QuoteExactInputSingleParams({
                tokenIn: WS,
                tokenOut: GOGGLZ,
                tickSpacing: TICK_SPACING,
                amountIn: 100 ether,
                sqrtPriceLimitX96: 0
            })
        );

        console.log("amountOut", amountOut);
        console.log("sqrtPriceX96After", sqrtPriceX96After);
        console.log("initializedTicksCrossed", initializedTicksCrossed);
        console.log("gasEstimate", gasEstimate);
    }

    function test_quoteExactInput() public {
        bytes memory path = abi.encodePacked(
            WS,
            int24(TICK_SPACING),
            GOGGLZ
        );
        
        (uint256 amountOut,
         uint160[] memory sqrtPriceX96AfterList,
         uint32[] memory initializedTicksCrossedList,
         uint256 gasEstimate) = IQuoterV2(QUOTERV2).quoteExactInput(
            path,
            100 ether
        );

        console.log("amountOut", amountOut);
        console.log("sqrtPriceX96AfterList length", sqrtPriceX96AfterList.length);
        console.log("initializedTicksCrossedList length", initializedTicksCrossedList.length);
        console.log("gasEstimate", gasEstimate);
    }
}
