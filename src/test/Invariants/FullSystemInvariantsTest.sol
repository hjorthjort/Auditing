// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "./InvariantBaseTest.t.sol";

contract FullSystemInvariantsTest is InvariantBaseTest {

    function setUp() public virtual override {
        selectors.push(this.depositCollateral.selector);
        selectors.push(this.withdrawCollateral.selector);
        selectors.push(this.borrowCollateral.selector);
        selectors.push(this.repayDebt.selector);
        selectors.push(this.repayDebtViaBurn.selector);
        selectors.push(this.transmuterStake.selector);
        selectors.push(this.transmuterClaim.selector);

        selectors.push(this.mine.selector);

        super.setUp();
    }

    /* INVARIANTS */

    // Total deposited equals the sum of all individual CDPs
    // This uses getCDP which calculates balances/debts without updating storage
    function invariantConsistentCollateral() public {
        address[] memory users = targetSenders();

        uint256 totalDeposited;

        for (uint256 i; i < users.length; ++i) {
            (uint256 collateral , ,) = alchemist.getCDP(users[i]);

            totalDeposited += collateral;
        }

        assertEq(totalDeposited, alchemist.getTotalDeposited());
    }

    // Underlying value of collateral equals sum of all user accounts
    // This test uses poke() to perform an actual storage update to the user account 
    function invariantConsistentCollateralwithPoke() public {
        address[] memory users = targetSenders();

        uint256 totalDeposited;

        for (uint256 i; i < users.length; ++i) {
            alchemist.poke(users[i]);

            totalDeposited += alchemist.totalValue(users[i]);
        }

        assertEq(totalDeposited, alchemist.convertYieldTokensToDebt(alchemist.getTotalDeposited()));
    }

    // Total debt in the system is equal to sum of all user debts
    function invariantConsistentDebt() public {
        address[] memory users = targetSenders();

        uint256 totalDebt;

        for (uint256 i; i < users.length; ++i) {
            (uint256 collateral, uint256 debt,) = alchemist.getCDP(users[i]);

            totalDebt += debt;
        }

        assertEq(totalDebt, alchemist.totalDebt());
    }

    // Supply of debt tokens must be greater or equal to debt in the system
    function invariantDebtTokenSupply() public {
        assertGe(alToken.totalSupply(), alchemist.totalDebt());
    }   

    // // Currently broken due to burns. Awaiting team decision
    // // Amount stakes in the transmuter cannot exceed the total debt in the alchemist plus the debt value of yield tokens in the transmuter
    // function invariantTransmuterStakeLessThanTotalDebt() public {
    //     uint256 totalLocked = transmuterLogic.totalLocked() > alchemist.convertYieldTokensToDebt(fakeYieldToken.balanceOf(address(transmuterLogic))) ? transmuterLogic.totalLocked() - alchemist.convertYieldTokensToDebt(fakeYieldToken.balanceOf(address(transmuterLogic))) : 0;
    //     assertLe(totalLocked, alchemist.totalDebt());
    // }
}