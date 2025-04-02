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

contract TestPairName is Test {
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

    address pair;
    address pair2;

    function setUp() public {
        // deploy fake tokens
        token0 = new MockERC20();
        token1 = new MockERC20();
        // initialize the mock tokens
        token0.initialize("Scam", "ANDRE", 18);
        token1.initialize("Andre", "COOKPLEASE", 18);

        // deploy factory + router
        factory = new PairFactory(VOTER, TREASURY, ACCESS_MANAGER, FEE_RECIPIENT);
        router = new Router(address(factory), WETH);

        // deal tokens and approve to router
        deal(address(token0), address(this), INITIAL_LIQUIDITY);
        deal(address(token1), address(this), INITIAL_LIQUIDITY);
        token0.approve(address(router), type(uint256).max);
        token1.approve(address(router), type(uint256).max);

        // initialize stable pool
        pair = factory.createPair(address(token0), address(token1), true);
        // initialize volatile pool
        pair2 = factory.createPair(address(token0), address(token1), false);
    }

    function test_nameCheck() public {
        console.log("starting pair name testing ------");
        console.log("Stable test ------------");
        console.log("token name", Pair(pair).name());
        console.log("token symbol", Pair(pair).symbol());
        console.log("Volatile test------------");
        console.log("token name", Pair(pair2).name());
        console.log("token symbol", Pair(pair2).symbol());
    }
}
