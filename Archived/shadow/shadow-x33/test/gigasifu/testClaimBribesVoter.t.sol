// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;
import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {RewardClaimers2} from "contracts/CL/periphery/RewardClaimers2.sol";
import {IVoteModule} from "contracts/interfaces/IVoteModule.sol";
import {IXShadow} from "contracts/interfaces/IXShadow.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract RewardClaimers2Test is Test {
    RewardClaimers2 public rewardClaimers2;
    address public LEGACY_ROUTER = 0x1D368773735ee1E678950B7A97bcA2CafB330CDc;
    address public GIGASAFU = 0xB3bfB32977cFd6200AB9537E3703e501d8381c9B;
    address public VOTE_MODULE = 0xDCB5A24ec708cc13cee12bFE6799A78a79b666b4;
    address public XSHADOW = 0x5050bc082FF4A74Fb6B0B04385dEfdDB114b2424;
    address public ACCESS_HUB = 0x5e7A9eea6988063A4dBb9CcDDB3E04C923E8E37f; 
    address public SHADOW_S_LP = 0xF19748a0E269c6965a84f8C98ca8C47A064D4dd0;

    function setUp() public {
        rewardClaimers2 = new RewardClaimers2(
            LEGACY_ROUTER,
            ACCESS_HUB,
            0x2C1a605f843A2E18b7d7772f0Ce23c236acCF7f5, // RAMSES_V3_FACTORY
            0x19609B03C976CCA288fbDae5c21d4290e9a4aDD7, // NFP_MANAGER
            0x1E131D755e487b65749dA8F8f43820575d094E3C, // VOTER
            XSHADOW,
            0x55A75C8F00EA96F258859B0e642E3Ffb1191959D  // SHADOW
        );
    }

    function test_claimRewards() public {
        address[] memory feeDistributors = new address[](3);
        feeDistributors[0] = 0xB952D1db74A4bB9d97c26b2fCf110E10B70811a1;
        feeDistributors[1] = 0xB952D1db74A4bB9d97c26b2fCf110E10B70811a1;
        feeDistributors[2] = 0xB952D1db74A4bB9d97c26b2fCf110E10B70811a1;

        address[][] memory tokens = new address[][](3);
        for (uint i = 0; i < 3; i++) {
            tokens[i] = new address[](4);
            tokens[i][0] = 0x039e2fB66102314Ce7b64Ce5Ce3E5183bc94aD38;
            tokens[i][1] = 0x3333b97138D4b086720b5aE8A7844b1345a33333;
            tokens[i][2] = 0x5050bc082FF4A74Fb6B0B04385dEfdDB114b2424;
            tokens[i][3] = 0xF19748a0E269c6965a84f8C98ca8C47A064D4dd0;
        }

        // whitelist RewardClaimers2 in xShadow
        vm.startPrank(ACCESS_HUB);
        address[] memory exemptAddresses = new address[](1);
        exemptAddresses[0] = address(rewardClaimers2);
        bool[] memory statuses = new bool[](1);
        statuses[0] = true;
        IXShadow(XSHADOW).setExemption(exemptAddresses, statuses);
        vm.stopPrank();

        // set admin rights for rewards claiming
        vm.startPrank(GIGASAFU);
        IVoteModule(VOTE_MODULE).setAdmin(address(rewardClaimers2));

        // deal some LPs to rewardClaimers2 to see if it works
        deal(SHADOW_S_LP, address(rewardClaimers2), 12345 ether);
        rewardClaimers2.claimLegacyIncentives(
            feeDistributors,
            tokens
        );
        vm.stopPrank();

        // log final balances for GIGASAFU
        console.log("=== Final Balances for GIGASAFU ===");
        for (uint i = 0; i < tokens[0].length; i++) {
            address token = tokens[0][i];
            uint256 balance = IERC20(token).balanceOf(GIGASAFU);
            console.log("Token:", token);
            console.log("Balance:", balance);
            console.log("-----------------");
        }
    }
}