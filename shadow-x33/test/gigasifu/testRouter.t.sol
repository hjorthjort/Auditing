// SPDX-License-Identifier: MIT
pragma solidity ^0.8.x;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {Router} from "contracts/Router.sol";
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {IRouter} from "contracts/interfaces/IRouter.sol";

contract TestRouter is Test {
    Router public router;
    address constant WS = 0x039e2fB66102314Ce7b64Ce5Ce3E5183bc94aD38;
    address constant USDCe = 0x29219dd400f2Bf60E5a23d13Be72B486D4038894;
    address SHEDEW = 0x69690ED6644B0E735c05B49034b6283eD5bB6969;
    address SCETH = 0x3bcE5CB273F0F148010BbEa2470e7b5df84C7812;
    
    address constant FACTORY = 0x2dA25E7446A70D7be65fd4c053948BEcAA6374c8;
    address constant ROUTER = 0x1D368773735ee1E678950B7A97bcA2CafB330CDc;
    
    address internal alice;
    uint256 internal swapAmountIn;

    function setUp() public {
        alice = makeAddr('alice');
        vm.startPrank(alice);
        
        // Pre-fund and approve both tokens
        deal(SCETH, alice, 100_000_000_000 ether);
        deal(SHEDEW, alice, 100_000_000_000 ether);
        IERC20(SCETH).approve(ROUTER, type(uint256).max);
        IERC20(SHEDEW).approve(ROUTER, type(uint256).max);
        swapAmountIn = 0.01 ether;
        console.log("Swapping %s SHEDEW to SCETH", swapAmountIn);
        vm.stopPrank();
    }

    function test_v2SwapReverse() public {
        vm.startPrank(alice);
        
        Router.route[] memory routes = new Router.route[](1);
        routes[0] = IRouter.route({
            from: SHEDEW,
            to: SCETH,
            stable: false  // Use volatile (v2-style) pool
        });

        uint256[] memory amounts = IRouter(ROUTER).getAmountsOut(swapAmountIn, routes);
        console.log("Expected Output:", amounts[1]);

        IRouter(ROUTER).swapExactTokensForTokens(
            swapAmountIn,
            0, // amountOutMin
            routes,
            alice,
            block.timestamp + 1000
        );

        console.log("SCETH Balance After:", IERC20(SCETH).balanceOf(alice));
        vm.stopPrank();
    }
} 