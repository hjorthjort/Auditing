
// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.26;

import {Test, console} from "forge-std/Test.sol";

contract Rounding is Test {

    function testDebtFeeWeightRounding(uint256 protocolFee, uint256 blockDistance) public {
      vm.assume(protocolFee <= 1000);
      vm.assume(blockDistance <= 100);

      uint256 blocksPerYear = 2_100_000;
      uint256 BPS = 10_000;

      uint256 debtFeeWeight = 1e27;

      uint256 debtFeeWeight1 = debtFeeWeight * (1e27 + ((protocolFee * 1e27 / BPS) * (/*block.number - lastEarmarkBlock*/ blockDistance) / blocksPerYear)) / 1e27;
      uint256 debtFeeWeight2 = debtFeeWeight + (debtFeeWeight * (protocolFee * (/*block.number - lastEarmarkBlock*/ blockDistance) / (blocksPerYear * BPS)));

      assertEq(debtFeeWeight1,debtFeeWeight2);
    }
}