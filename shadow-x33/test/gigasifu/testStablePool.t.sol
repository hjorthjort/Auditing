// SPDX-License-Identifier: MIT
pragma solidity ^0.8.x;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {MockERC20} from "forge-std/mocks/MockERC20.sol";
import {Router} from "contracts/Router.sol";
import {PairFactory} from "contracts/factories/PairFactory.sol";
import {IRouter} from "contracts/interfaces/IRouter.sol";
import {console} from "forge-std/console.sol";
import {Pair} from "contracts/Pair.sol";

contract StablePoolTest is Test {
    MockERC20 public token0;
    MockERC20 public token1;
    Router public router;
    PairFactory public factory;
    address public constant WETH = address(0x1);
    address public constant TREASURY = address(0x2);
    address public constant ACCESS_MANAGER = address(0x3);
    address public constant VOTER = address(0x4);
    address public constant FEE_RECIPIENT = address(0x5);
    uint256 public constant INITIAL_LIQUIDITY = 100 * 1e18;
    uint256 public constant SWAP_AMOUNT = 1 * 1e17;

    address pair;

    function setUp() public {
        // deploy fake tokens
        token0 = new MockERC20();
        token1 = new MockERC20();
        // initialize the mock tokens
        token0.initialize("test", "TEEE", 18);
        token1.initialize("cap", "INSANE", 18);

        // deploy factory + router
        factory = new PairFactory(
            VOTER,
            TREASURY,
            ACCESS_MANAGER,
            FEE_RECIPIENT
        );
        router = new Router(address(factory), WETH);

        // deal tokens and approve to router
        deal(address(token0), address(this), INITIAL_LIQUIDITY);
        deal(address(token1), address(this), INITIAL_LIQUIDITY);
        token0.approve(address(router), type(uint256).max);
        token1.approve(address(router), type(uint256).max);

        // initialize stable pool
        pair = factory.createPair(address(token0), address(token1), true);
    }

    function testStableSwap() public {
        // log initial reserves
        (uint256 reserve0, uint256 reserve1, ) = Pair(pair).getReserves();
        console.log("Initial reserves:");
        console.log("Reserve0:", reserve0);
        console.log("Reserve1:", reserve1);

        router.addLiquidity(
            address(token0),
            address(token1),
            true, // stable pool
            1e18, // token0 amount
            1e18, // token1 amount
            0, // min amount0
            0, // min amount1
            address(this),
            block.timestamp
        );

        // log reserves after add
        (reserve0, reserve1, ) = Pair(pair).getReserves();
        console.log("Reserves after adding liquidity:");
        console.log("Reserve0:", reserve0);
        console.log("Reserve1:", reserve1);
        //console.log("Amount0 added:", amount0);
        //console.log("Amount1 added:", amount1);
        uint liquidity = Pair(pair).balanceOf(address(this));
        console.log("LP tokens:", liquidity);
        console.log("token name", Pair(pair).name());
        console.log ("token symbol", Pair(pair).symbol());

        // // create swap route
        // IRouter.route[] memory routes = new IRouter.route[](1);
        // routes[0] = IRouter.route({
        //     from: address(token0),
        //     to: address(token1),
        //     stable: true
        // });

        // IRouter.route[] memory routes2 = new IRouter.route[](1);
        // routes2[0] = IRouter.route({
        //     from: address(token1),
        //     to: address(token0),
        //     stable: true
        // });

        // // log token balances before swap
        // uint256 token0BalanceBefore = token0.balanceOf(address(this));
        // uint256 token1BalanceBefore = token1.balanceOf(address(this));
        // console.log("Balances before swap:");
        // console.log("Token0 balance:", token0BalanceBefore);
        // console.log("Token1 balance:", token1BalanceBefore);

        // // perform swap
        // uint256 amountIn = SWAP_AMOUNT;
        // uint256[] memory amounts = router.getAmountsOut(amountIn, routes);

        // console.log("Expected output:", amounts[1]);

        // uint256[] memory swapResult = router.swapExactTokensForTokens(
        //     amountIn,
        //     0, // min amount out
        //     routes,
        //     address(this),
        //     block.timestamp + 2
        // );

        // for (uint256 i; i < 10; ++i) {
        //     router.swapExactTokensForTokens(
        //         amountIn,
        //         0,
        //         routes,
        //         address(this),
        //         block.timestamp + 2
        //     );
        //     router.swapExactTokensForTokens(
        //         amountIn,
        //         0,
        //         routes2,
        //         address(this),
        //         block.timestamp + 2
        //     );
        // }

        // // log reserves after swap
        // (reserve0, reserve1, ) = Pair(pair).getReserves();
        // console.log("\nReserves after swap:");
        // console.log("Reserve0:", reserve0);
        // console.log("Reserve1:", reserve1);

        // console.log("Combined Reserves", reserve0 + reserve1);

        // // log final balances
        // uint256 token0BalanceAfter = token0.balanceOf(address(this));
        // uint256 token1BalanceAfter = token1.balanceOf(address(this));
        // console.log("\nBalances after swap:");
        // console.log("Token0 balance:", token0BalanceAfter);
        // console.log("Token1 balance:", token1BalanceAfter);
        // console.log("Token0 spent:", token0BalanceBefore - token0BalanceAfter);
        // console.log(
        //     "Token1 received:",
        //     token1BalanceAfter - token1BalanceBefore
        // );
    }
}
