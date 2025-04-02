// scratchpad for quick random tests
pragma solidity ^0.8.x;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {IVoteModule} from 'contracts/interfaces/IVoteModule.sol';
import {IVoter} from 'contracts/interfaces/IVoter.sol';
import {Voter} from 'contracts/Voter.sol';
import {IAccessHub} from 'contracts/interfaces/IAccessHub.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
contract SafuScratchpad is Test {
    address VOTE_MODULE = 0xDCB5A24ec708cc13cee12bFE6799A78a79b666b4;
    // address LOCKED_GUY = 0x96754E677b271A453f26Bed6760DeF0F9d9D4C66;
    // address LOCKED_GUY = 0x85b26b5180718824b646228F9Ce60C5486E76B30;
    address LOCKED_GUY = 0x7D1019bedDbDaBc00f9db01EcF895fd779BC4caB;
    address VOTER = 0x3aF1dD7A2755201F8e2D6dCDA1a61d9f54838f4f;
    address PROBLEM_POOL = 0x097D8B97d15567fB9966BA7BFAeC35cB86B09834;
    address ACCESS_HUB = 0x5e7A9eea6988063A4dBb9CcDDB3E04C923E8E37f;
    address MSIG = 0x5Be2e859D0c2453C9aA062860cA27711ff553432;
    address XSHADOW = 0x5050bc082FF4A74Fb6B0B04385dEfdDB114b2424;

    function test_withdrawVoteModule() public {
        vm.startPrank(LOCKED_GUY);

        IVoteModule(VOTE_MODULE).withdrawAll();

        vm.stopPrank();
    }

    function test_reviveGaugeAndWithdraw() public {
        address[] memory pairs = new address[](1);
        pairs[0] = PROBLEM_POOL;
        vm.prank(MSIG);
        IAccessHub(ACCESS_HUB).reviveGauge(pairs);
        vm.prank(LOCKED_GUY);
        IVoteModule(VOTE_MODULE).withdrawAll();
    }

    function test_moveTickspaceAndWithdraw() public {
        console.log("BEFORE MOVE TICKSPACE:", IVoteModule(VOTE_MODULE).balanceOf(LOCKED_GUY));
        vm.prank(MSIG);
        IAccessHub(ACCESS_HUB).setMainTickSpacingInVoter(0x039e2fB66102314Ce7b64Ce5Ce3E5183bc94aD38, 0x79bbF4508B1391af3A0F4B30bb5FC4aa9ab0E07C, 200);
        vm.startPrank(LOCKED_GUY);
        console.log("AFTER MOVE TICKSPACE:", IVoteModule(VOTE_MODULE).balanceOf(LOCKED_GUY));
        IVoteModule(VOTE_MODULE).withdrawAll();
        console.log("AFTER WITHDRAW (wallet balance):", IERC20(XSHADOW).balanceOf(LOCKED_GUY));
    }

    function test_moveTickspaceResetAndMoveBack() public {
        vm.prank(MSIG);
        IAccessHub(ACCESS_HUB).setMainTickSpacingInVoter(0x039e2fB66102314Ce7b64Ce5Ce3E5183bc94aD38, 0x79bbF4508B1391af3A0F4B30bb5FC4aa9ab0E07C, 200);
        vm.prank(ACCESS_HUB);
        IVoter(VOTER).reset(LOCKED_GUY);
        vm.prank(MSIG);
        IAccessHub(ACCESS_HUB).setMainTickSpacingInVoter(0x039e2fB66102314Ce7b64Ce5Ce3E5183bc94aD38, 0x79bbF4508B1391af3A0F4B30bb5FC4aa9ab0E07C, 100);
    }

}
