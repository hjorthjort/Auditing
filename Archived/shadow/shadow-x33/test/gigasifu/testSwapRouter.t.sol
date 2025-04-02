// SPDX-License-Identifier: MIT
pragma solidity ^0.8.x;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {SwapRouter} from "contracts/CL/periphery/SwapRouter.sol";
import {ISwapRouter} from "contracts/CL/periphery/interfaces/ISwapRouter.sol";
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IV3Pool {
    function slot0() external view returns (uint160 sqrtPriceX96, int24 tick, uint16 observationIndex, uint16 observationCardinality, uint16 observationCardinalityNext, uint8 feeProtocol, bool unlocked);
}

interface IAlgebraPool {
    function globalState() external view returns (uint160 price, int24 tick, uint16 fee, uint16 timepointIndex, uint8 communityFeeToken0, uint8 communityFeeToken1);
}

interface IAlgebraSwapRouter {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 limitSqrtPrice;
    }

    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);


}

contract TestSwapRouter is Test {
    SwapRouter public router;
    address constant WS = 0x039e2fB66102314Ce7b64Ce5Ce3E5183bc94aD38;
    address constant GOGGLZ = 0x9fDbC3f8Abc05Fa8f3Ad3C17D2F806c1230c4564;
    address constant USDCe = 0x29219dd400f2Bf60E5a23d13Be72B486D4038894;
    
    address constant SHADOW_ROUTER = 0x5543c6176FEb9B4b179078205d7C29EEa2e2d695;
    address constant ALGEBRA_ROUTER = 0x4882198dd2064D1E35b24735e6B9E5e3B45AcD6b;

    address constant SHADOW_POOL = 0x324963c267C354c7660Ce8CA3F5f167E05649970;
    address constant ALGEBRA_POOL = 0x9f46dd8F2A4016C26c1Cf1f4ef90e5E1928D756B;

    address internal alice;
    uint256 internal swapAmountIn;
    function setUp() public {
        alice = makeAddr('alice');
        vm.startPrank(alice);
        
        // Pre-fund and approve for both routers
        deal(WS, alice, 100_000_000_000 ether);
        IERC20(WS).approve(SHADOW_ROUTER, type(uint256).max);
        IERC20(WS).approve(ALGEBRA_ROUTER, type(uint256).max);
        swapAmountIn = 1_000 ether;
        console.log("Swapping %s WS to USDCe", swapAmountIn);
        vm.stopPrank();
    }

    function test_shadowSwap() public {
        vm.startPrank(alice);
        (,int24 tickBefore,,,,,) = IV3Pool(SHADOW_POOL).slot0();
        console.log("ShadowTickBeforeSwap:", tickBefore);
        ISwapRouter(SHADOW_ROUTER).exactInputSingle(
            ISwapRouter.ExactInputSingleParams({
                tokenIn: WS,
                tokenOut: USDCe,
                tickSpacing: 50,
                recipient: alice,
                deadline: block.timestamp + 1000,
                amountIn: swapAmountIn,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            })
        );
        (,int24 tickAfter,,,,,) = IV3Pool(SHADOW_POOL).slot0();
        console.log("ShadowTickAfterSwap:", tickAfter);
        console.log("Difference:", tickAfter - tickBefore);
        vm.stopPrank();
    }

    function test_algebraSwap() public {
        vm.startPrank(alice);
        (,int24 tickBefore,,,,) = IAlgebraPool(ALGEBRA_POOL).globalState();
        console.log("AlgebraTickBeforeSwap:", tickBefore);
        IAlgebraSwapRouter(ALGEBRA_ROUTER).exactInputSingle(
            IAlgebraSwapRouter.ExactInputSingleParams({
                tokenIn: WS,
                tokenOut: USDCe,
                recipient: alice,
                deadline: block.timestamp + 1000,
                amountIn: swapAmountIn,
                amountOutMinimum: 0,
                limitSqrtPrice: 0
            })
        );  
        (,int24 tickAfter,,,,) = IAlgebraPool(ALGEBRA_POOL).globalState();
        console.log("AlgebraTickAfterSwap:", tickAfter);
        console.log("Difference:", tickAfter - tickBefore);
        vm.stopPrank();
    }
}
