// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {MixedRouteQuoterV1} from "contracts/CL/periphery/lens/MixedRouteQuoterV1.sol";
import {IMixedRouteQuoterV1} from "contracts/CL/periphery/interfaces/IMixedRouteQuoterV1.sol";
contract TestMixedQuoter is Test {
    IMixedRouteQuoterV1 public quoter;
    address WS = 0x039e2fB66102314Ce7b64Ce5Ce3E5183bc94aD38;
    address GOGGLZ = 0x9fDbC3f8Abc05Fa8f3Ad3C17D2F806c1230c4564;
    address SHEDEW = 0x69690ED6644B0E735c05B49034b6283eD5bB6969;
    address SCETH = 0x3bcE5CB273F0F148010BbEa2470e7b5df84C7812;

    function setUp() public {
        quoter = new MixedRouteQuoterV1(0xcD2d0637c94fe77C2896BbCBB174cefFb08DE6d7, 0x2dA25E7446A70D7be65fd4c053948BEcAA6374c8);
    }

    function test_quoteExactInput() public {
        bytes memory path = abi.encodePacked(WS, int24(100), GOGGLZ);
        uint256 amountIn = 100 ether;
        (uint256 amountOut, uint160[] memory v3SqrtPriceX96AfterList, uint32[] memory v3InitializedTicksCrossedList, uint256 v3SwapGasEstimate) = quoter.quoteExactInput(path, amountIn);
        console.log("amountOut", amountOut);
        console.log("v3SqrtPriceX96AfterList length", v3SqrtPriceX96AfterList.length);
        console.log("v3InitializedTicksCrossedList length", v3InitializedTicksCrossedList.length);
        console.log("v3SwapGasEstimate", v3SwapGasEstimate);
    }

    function test_quoteExactInputSingleV3() public {
        (uint256 amountOut, uint160 sqrtPriceX96After, uint32 initializedTicksCrossed, uint256 gasEstimate) = quoter.quoteExactInputSingleV3(
            IMixedRouteQuoterV1.QuoteExactInputSingleV3Params({
                tokenIn: WS,
                tokenOut: GOGGLZ,
                tickSpacing: 100,
                amountIn: 100 ether,
                sqrtPriceLimitX96: 0
            })
        );
        console.log("amountOut", amountOut);
        console.log("sqrtPriceX96After", sqrtPriceX96After);
        console.log("initializedTicksCrossed", initializedTicksCrossed);
        console.log("gasEstimate", gasEstimate);
    }

    function test_quoteExactInputQueso() public {
        // Encode path: token -> tickSpacing -> token -> tickSpacing -> token
        bytes memory path = abi.encodePacked(
            SHEDEW,
            uint24(8388609),
            SCETH
        );

        uint256 amountIn = 10 ether;
        
        
        (
            uint256 amountOut,
            uint160[] memory v3SqrtPriceX96AfterList,
            uint32[] memory v3InitializedTicksCrossedList,
            uint256 v3SwapGasEstimate
        ) = quoter.quoteExactInput(path, amountIn);
        
        console.log("amountOut", amountOut);
        console.log("v3SqrtPriceX96AfterList length", v3SqrtPriceX96AfterList.length);
        console.log("v3InitializedTicksCrossedList length", v3InitializedTicksCrossedList.length);
        console.log("v3SwapGasEstimate", v3SwapGasEstimate);
    }

    function test_quoteExactInputSingleV2() public {
        uint256 amountOut = quoter.quoteExactInputSingleV2(
            IMixedRouteQuoterV1.QuoteExactInputSingleV2Params({
                tokenIn: SCETH,
                tokenOut: SHEDEW,
                amountIn: 0.01 ether,
                stable: false
            })
        );
        
        console.log("V2 Direct amountOut", amountOut);
    }

    function test_quoteV2SwapReversePath() public {
        // Using path encoding - 0x800000 (hex for 8388608) indicates V2 pool
        bytes memory path = abi.encodePacked(
            SHEDEW,
            uint24(8388609), // Flag for V2 volatile pool
            SCETH
        );

        (
            uint256 amountOut,
            ,
            ,
        ) = quoter.quoteExactInput(path, 0.01 ether);
        
        console.log("Expected V2 swap output (path method):", amountOut);
    }

    



}
