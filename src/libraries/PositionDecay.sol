// SPDX-License-Identifier: BSD-4-Clause
/*
 * This file is based on code originally distributed under the BSD-4-Clause license.
 * Modifications made by <aphoticjezter@gmail.com>, 2025.
 *
 * Original notice:
 * ABDK Math 64.64 Smart Contract Library.  Copyright © 2019 by ABDK Consulting.
 * Author: Mikhail Vladimirov <mikhail.vladimirov@gmail.com>
 */
pragma solidity ^0.8.7;

/* Fractional decay of Alchemist v3 positions via log2 weights in UQ136.120
 * fixed point representation.
 * User earmark/redemption can be represented as a product of fractions,
 * that approach zero as users are earmarked and redeemed.
 *
 * To deal with precision loss over time, we use the log(a*b)=log(a)+log(b)
 * identity to transform these fractions into summed logarithms.
 * Since these logarithms will be negative for all fractions in 0<x<1.0
 * we use the negated value of the logarithm for both exp and log, resulting
 * in monotonically non-decreasing weights for any non-zero earmark/redemption.
 */

library PositionDecay {
  /**
   * Result of Log2NegFrac(1)
   * Defined also as the largest input to Exp2NegFrac that produces a non-zero output
   */
  uint256 private constant LOG2NEGFRAC_1 = 0x80000000000000000000000000000000;

  /**
   * Calculate -log2((total-increment)/total)
   * Revert if total > uint128.max or increment > total
   *
   * @param increment (0 >= increment >= total)
   * @param total (0 >= total >= uint128.max)
   * @return UQ136.120 (0 > weightIncrement >= (128.0 + 2^-120))
   */
  function WeightIncrement(uint256 increment, uint256 total) internal pure returns (uint256) {
    unchecked {
      require(increment <= total);           //support ratios of 1.0 or less
      require(total <= type(uint128).max);   //Overflow check for (total - increment)<<128

      //By this check, and require(increment <= total <= uint128.max), we avoid div by zero
      if (increment == 0) {
        //log2(1.0) produces no weight increment
        return 0;
      }

      uint256 ratio = (((total - increment) << 128)+((total-1)>>1)) / total;
      if (ratio == 0) {
        //return smallest weight increase where Exp2NegFrac returns zero
        return LOG2NEGFRAC_1+1;
      }
      return Log2NegFrac(ratio);
    }
  }

  /**
   * Calculate value-value*(2^-weightDelta)
   * Revert if value > uint128.max
   *
   * @param value (0 >= value >= uint128.max)
   * @param weightDelta (0 >= weightDelta)
   * @return (0 >= return >= value)
   */
  function ScaleByWeightDelta(uint256 value, uint256 weightDelta) internal pure returns (uint256) {
    unchecked {
      require(value <= type(uint128).max);   //Overflow check for value * Exp2NegFrac()
      
      if (weightDelta == 0) {
        //No decay has occurred
        return 0;
      }

      //This check is unnecessary given Exp2NegFrac repeats it
      //if (weightDelta > LOG2NEGFRAC_1) {
      //Full decay has occurred
      //  return value;
      //}

      return value - ((value * Exp2NegFrac(weightDelta) + (type(uint128).max>>1)) >> 128);
    }
  }


  /**
   * Calculate negative log2 of x.  Revert if x == 0.
   *
   * @param x UQ128.128 (0 > x > 1.0)
   * @return UQ136.120 (0 > value >=128.0)
   */
  function Log2NegFrac(uint256 x) private pure returns (uint256) {
    unchecked {
      if (x >= 2**128) return 0;//Underflow

      require(x > 0);

      int256 msb = 0;
      uint256 xc = x;
      if (xc >= 0x10000000000000000) { xc >>= 64; msb += 64; }
      if (xc >= 0x100000000) { xc >>= 32; msb += 32; }
      if (xc >= 0x10000) { xc >>= 16; msb += 16; }
      if (xc >= 0x100) { xc >>= 8; msb += 8; }
      if (xc >= 0x10) { xc >>= 4; msb += 4; }
      if (xc >= 0x4) { xc >>= 2; msb += 2; }
      if (xc >= 0x2) msb += 1;  // No need to shift xc anymore

      int256 result = (msb - 128) << 120;
      uint256 ux = uint256(x) << uint256(127 - msb);
      for (int256 bit = 0x800000000000000000000000000000; bit > 0; bit >>= 1) {
        ux *= ux;
        uint256 b = ux >> 255;
        ux >>= 127 + b;
        result += bit * int256 (b);
      }
  
      return  uint256(-result);
    }
  }

  /**
   * Calculate 2^(-x).  Revert on overflow.
   *
   * @param x UQ136.120 negative exponent (0 > x)
   * @return UQ128.128 (0 > value > 1.0)
   */
  function Exp2NegFrac(uint256 x) private pure returns (uint256) {
    unchecked {
      if (x > LOG2NEGFRAC_1) return 0; // Underflow

      int256 nx = -int256(x);

      require (nx < 0); // Overflow

      // To account for precision loss resulting from the shifts
      // all constants below are rounded and result is given an offset

      // Subtract 2 for rounding bias
      uint256 result = 0x80000000000000000000000000000000 + 2;

      if (nx & 2**119 > 0)
        result += result * 0xd413cccfe779921165f626cdd52afa7c + 2**128 - 1 >> 129;
      if (nx & 2**118 > 0)
        result += result * 0xc1bf828c6dc54b7a356918c17217b7b3 + 2**129 - 1 >> 130;
      if (nx & 2**117 > 0)
        result += result * 0xb95c1e3ea8bd6e6fbe4628758a53c902 + 2**130 - 1 >> 131;
      if (nx & 2**116 > 0)
        result += result * 0xb5586cf9890f6298b92b71842a983643 + 2**131 - 1 >> 132;
      if (nx & 2**115 > 0)
        result += result * 0xb361a62b0ae875cf8a91d6d19482ffca + 2**132 - 1 >> 133;
      if (nx & 2**114 > 0)
        result += result * 0x59347cef00c1dcdef95949ef4537bd28 + 2**132 - 1 >> 133;
      if (nx & 2**113 > 0)
        result += result * 0x2c7b53f6666adb094cd5c66db9bf4800 + 2**132 - 1 >> 133;
      if (nx & 2**112 > 0)
        result += result * 0x1635f4b5797dac2535627d823b92a88b + 2**132 - 1 >> 133;
      if (nx & 2**111 > 0)
        result += result * 0xb190db43813d43fe33a5299e5ecf38d + 2**132 - 1 >> 133;
      if (nx & 2**110 > 0)
        result += result * 0x58c0bc5d19d8a0da437f91344740210 + 2**132 - 1 >> 133;
      if (nx & 2**109 > 0)
        result += result * 0x2c5e72080a3f425179538ab863cbc0e + 2**132 - 1 >> 133;
      if (nx & 2**108 > 0)
        result += result * 0x162ebdffb8ed7471c62ce395272e4cd + 2**132 - 1 >> 133;
      if (nx & 2**107 > 0)
        result += result * 0xb17403f73f2dad959a9630122f87c8 + 2**132 - 1 >> 133;
      if (nx & 2**106 > 0)
        result += result * 0x58b986fb52923a130b86918d1cf67b + 2**132 - 1 >> 133;
      if (nx & 2**105 > 0)
        result += result * 0x2c5ca4bdc0a8ea88afab32a52404db + 2**132 - 1 >> 133;
      if (nx & 2**104 > 0)
        result += result * 0x162e4aaeeb8080c317e9495bd07f95 + 2**132 - 1 >> 133;
      if (nx & 2**103 > 0)
        result += result * 0xb17236b7935c5ddb03d36fa99f583 + 2**132 - 1 >> 133;
      if (nx & 2**102 > 0)
        result += result * 0x58b913abd8d949af9159802f6f93b + 2**132 - 1 >> 133;
      if (nx & 2**101 > 0)
        result += result * 0x2c5c87e9f0620c1c05b07353a2dae + 2**132 - 1 >> 133;
      if (nx & 2**100 > 0)
        result += result * 0x162e4379f933b3f121d40d222ec70 + 2**132 - 1 >> 133;
      if (nx & 2**99 > 0)
        result += result * 0xb17219e3cdb2ff39429b7982c514 + 2**132 - 1 >> 133;
      if (nx & 2**98 > 0)
        result += result * 0x58b90c76e7e02c8d1ed758b94582 + 2**132 - 1 >> 133;
      if (nx & 2**97 > 0)
        result += result * 0x2c5c861cb431ec233c78045054bf + 2**132 - 1 >> 133;
      if (nx & 2**96 > 0)
        result += result * 0x162e4306aa2970dcdb2ddfa37fed + 2**132 - 1 >> 133;
      if (nx & 2**95 > 0)
        result += result * 0xb1721816918d7cbbf08d8b65e06 + 2**132 - 1 >> 133;
      if (nx & 2**94 > 0)
        result += result * 0x58b90c0398d73d284278e4e6f58 + 2**132 - 1 >> 133;
      if (nx & 2**93 > 0)
        result += result * 0x2c5c85ffe06fbe715456433e0d7 + 2**132 - 1 >> 133;
      if (nx & 2**92 > 0)
        result += result * 0x162e42ff7538e7354b033e89f39 + 2**132 - 1 >> 133;
      if (nx & 2**91 > 0)
        result += result * 0xb17217f9bdcb59a7839db90476 + 2**132 - 1 >> 133;
      if (nx & 2**90 > 0)
        result += result * 0x58b90bfc63e6b4d461b437ca20 + 2**132 - 1 >> 133;
      if (nx & 2**89 > 0)
        result += result * 0x2c5c85fe13339c6a8373fff9f7 + 2**132 - 1 >> 133;
      if (nx & 2**88 > 0)
        result += result * 0x162e42ff01e9deb55bb48aaa8d + 2**132 - 1 >> 133;
      if (nx & 2**87 > 0)
        result += result * 0xb17217f7f08f37ab5036a35b5 + 2**132 - 1 >> 133;
      if (nx & 2**86 > 0)
        result += result * 0x58b90bfbf097ac55c614e9998 + 2**132 - 1 >> 133;
      if (nx & 2**85 > 0)
        result += result * 0x2c5c85fdf65fda4aeab37b54f + 2**132 - 1 >> 133;
      if (nx & 2**84 > 0)
        result += result * 0x162e42fefab4ee2d7749535e3 + 2**132 - 1 >> 133;
      if (nx & 2**83 > 0)
        result += result * 0xb17217f7d3bb758bc21399e4 + 2**132 - 1 >> 133;
      if (nx & 2**82 > 0)
        result += result * 0x58b90bfbe962bbcde2fd61b3 + 2**132 - 1 >> 133;
      if (nx & 2**81 > 0)
        result += result * 0x2c5c85fdf4929e28f1fbc0aa + 2**132 - 1 >> 133;
      if (nx & 2**80 > 0)
        result += result * 0x162e42fefa419f24f91d299d + 2**132 - 1 >> 133;
      if (nx & 2**79 > 0)
        result += result * 0xb17217f7d1ee3969c9667cb + 2**132 - 1 >> 133;
      if (nx & 2**78 > 0)
        result += result * 0x58b90bfbe8ef6cc564d28ba + 2**132 - 1 >> 133;
      if (nx & 2**77 > 0)
        result += result * 0x2c5c85fdf475ca66d271195 + 2**132 - 1 >> 133;
      if (nx & 2**76 > 0)
        result += result * 0x162e42fefa3a6a34713a819 + 2**132 - 1 >> 133;
      if (nx & 2**75 > 0)
        result += result * 0xb17217f7d1d165a7a9dbe0 + 2**132 - 1 >> 133;
      if (nx & 2**74 > 0)
        result += result * 0x58b90bfbe8e837d4dcefe5 + 2**132 - 1 >> 133;
      if (nx & 2**73 > 0)
        result += result * 0x2c5c85fdf473fd2ab07870 + 2**132 - 1 >> 133;
      if (nx & 2**72 > 0)
        result += result * 0x162e42fefa39f6e568bc57 + 2**132 - 1 >> 133;
      if (nx & 2**71 > 0)
        result += result * 0xb17217f7d1cf986b87e33 + 2**132 - 1 >> 133;
      if (nx & 2**70 > 0)
        result += result * 0x58b90bfbe8e7c485d471c + 2**132 - 1 >> 133;
      if (nx & 2**69 > 0)
        result += result * 0x2c5c85fdf473e056ee58e + 2**132 - 1 >> 133;
      if (nx & 2**68 > 0)
        result += result * 0x162e42fefa39efb078347 + 2**132 - 1 >> 133;
      if (nx & 2**67 > 0)
        result += result * 0xb17217f7d1cf7b97c5c4 + 2**132 - 1 >> 133;
      if (nx & 2**66 > 0)
        result += result * 0x58b90bfbe8e7bd50e3ea + 2**132 - 1 >> 133;
      if (nx & 2**65 > 0)
        result += result * 0x2c5c85fdf473de89b237 + 2**132 - 1 >> 133;
      if (nx & 2**64 > 0)
        result += result * 0x162e42fefa39ef3d292c + 2**132 - 1 >> 133;
      if (nx & 2**63 > 0)
        result += result * 0xb17217f7d1cf79ca89a + 2**132 - 1 >> 133;
      if (nx & 2**62 > 0)
        result += result * 0x58b90bfbe8e7bcdd94e + 2**132 - 1 >> 133;
      if (nx & 2**61 > 0)
        result += result * 0x2c5c85fdf473de6cde7 + 2**132 - 1 >> 133;
      if (nx & 2**60 > 0)
        result += result * 0x162e42fefa39ef35f44 + 2**132 - 1 >> 133;
      if (nx & 2**59 > 0)
        result += result * 0xb17217f7d1cf79adb6 + 2**132 - 1 >> 133;
      if (nx & 2**58 > 0)
        result += result * 0x58b90bfbe8e7bcd660 + 2**132 - 1 >> 133;
      if (nx & 2**57 > 0)
        result += result * 0x2c5c85fdf473de6b11 + 2**132 - 1 >> 133;
      if (nx & 2**56 > 0)
        result += result * 0x162e42fefa39ef3581 + 2**132 - 1 >> 133;
      if (nx & 2**55 > 0)
        result += result * 0xb17217f7d1cf79abf + 2**132 - 1 >> 133;
      if (nx & 2**54 > 0)
        result += result * 0x58b90bfbe8e7bcd5f + 2**132 - 1 >> 133;
      if (nx & 2**53 > 0)
        result += result * 0x2c5c85fdf473de6af + 2**132 - 1 >> 133;
      if (nx & 2**52 > 0)
        result += result * 0x162e42fefa39ef358 + 2**132 - 1 >> 133;
      if (nx & 2**51 > 0)
        result += result * 0xb17217f7d1cf79ac + 2**132 - 1 >> 133;
      if (nx & 2**50 > 0)
        result += result * 0x58b90bfbe8e7bcd6 + 2**132 - 1 >> 133;
      if (nx & 2**49 > 0)
        result += result * 0x2c5c85fdf473de6b + 2**132 - 1 >> 133;
      if (nx & 2**48 > 0)
        result += result * 0x162e42fefa39ef35 + 2**132 - 1 >> 133;
      if (nx & 2**47 > 0)
        result += result * 0xb17217f7d1cf79b + 2**132 - 1 >> 133;
      if (nx & 2**46 > 0)
        result += result * 0x58b90bfbe8e7bcd + 2**132 - 1 >> 133;
      if (nx & 2**45 > 0)
        result += result * 0x2c5c85fdf473de7 + 2**132 - 1 >> 133;
      if (nx & 2**44 > 0)
        result += result * 0x162e42fefa39ef3 + 2**132 - 1 >> 133;
      if (nx & 2**43 > 0)
        result += result * 0xb17217f7d1cf7a + 2**132 - 1 >> 133;
      if (nx & 2**42 > 0)
        result += result * 0x58b90bfbe8e7bd + 2**132 - 1 >> 133;
      if (nx & 2**41 > 0)
        result += result * 0x2c5c85fdf473de + 2**132 - 1 >> 133;
      if (nx & 2**40 > 0)
        result += result * 0x162e42fefa39ef + 2**132 - 1 >> 133;
      if (nx & 2**39 > 0)
        result += result * 0xb17217f7d1cf8 + 2**132 - 1 >> 133;
      if (nx & 2**38 > 0)
        result += result * 0x58b90bfbe8e7c + 2**132 - 1 >> 133;
      if (nx & 2**37 > 0)
        result += result * 0x2c5c85fdf473e + 2**132 - 1 >> 133;
      if (nx & 2**36 > 0)
        result += result * 0x162e42fefa39f + 2**132 - 1 >> 133;
      if (nx & 2**35 > 0)
        result += result * 0xb17217f7d1cf + 2**132 - 1 >> 133;
      if (nx & 2**34 > 0)
        result += result * 0x58b90bfbe8e8 + 2**132 - 1 >> 133;
      if (nx & 2**33 > 0)
        result += result * 0x2c5c85fdf474 + 2**132 - 1 >> 133;
      if (nx & 2**32 > 0)
        result += result * 0x162e42fefa3a + 2**132 - 1 >> 133;
      if (nx & 2**31 > 0)
        result += result * 0xb17217f7d1d + 2**132 - 1 >> 133;
      if (nx & 2**30 > 0)
        result += result * 0x58b90bfbe8e + 2**132 - 1 >> 133;
      if (nx & 2**29 > 0)
        result += result * 0x2c5c85fdf47 + 2**132 - 1 >> 133;
      if (nx & 2**28 > 0)
        result += result * 0x162e42fefa4 + 2**132 - 1 >> 133;
      if (nx & 2**27 > 0)
        result += result * 0xb17217f7d2 + 2**132 - 1 >> 133;
      if (nx & 2**26 > 0)
        result += result * 0x58b90bfbe9 + 2**132 - 1 >> 133;
      if (nx & 2**25 > 0)
        result += result * 0x2c5c85fdf4 + 2**132 - 1 >> 133;
      if (nx & 2**24 > 0)
        result += result * 0x162e42fefa + 2**132 - 1 >> 133;
      if (nx & 2**23 > 0)
        result += result * 0xb17217f7d + 2**132 - 1 >> 133;
      if (nx & 2**22 > 0)
        result += result * 0x58b90bfbf + 2**132 - 1 >> 133;
      if (nx & 2**21 > 0)
        result += result * 0x2c5c85fdf + 2**132 - 1 >> 133;
      if (nx & 2**20 > 0)
        result += result * 0x162e42ff0 + 2**132 - 1 >> 133;
      if (nx & 2**19 > 0)
        result += result * 0xb17217f8 + 2**132 - 1 >> 133;
      if (nx & 2**18 > 0)
        result += result * 0x58b90bfc + 2**132 - 1 >> 133;
      if (nx & 2**17 > 0)
        result += result * 0x2c5c85fe + 2**132 - 1 >> 133;
      if (nx & 2**16 > 0)
        result += result * 0x162e42ff + 2**132 - 1 >> 133;
      if (nx & 2**15 > 0)
        result += result * 0xb17217f + 2**132 - 1 >> 133;
      if (nx & 2**14 > 0)
        result += result * 0x58b90c0 + 2**132 - 1 >> 133;
      if (nx & 2**13 > 0)
        result += result * 0x2c5c860 + 2**132 - 1 >> 133;
      if (nx & 2**12 > 0)
        result += result * 0x162e430 + 2**132 - 1 >> 133;
      if (nx & 2**11 > 0)
        result += result * 0xb17218 + 2**132 - 1 >> 133;
      if (nx & 2**10 > 0)
        result += result * 0x58b90c + 2**132 - 1 >> 133;
      if (nx & 2**9 > 0)
        result += result * 0x2c5c86 + 2**132 - 1 >> 133;
      if (nx & 2**8 > 0)
        result += result * 0x162e43 + 2**132 - 1 >> 133;
      if (nx & 2**7 > 0)
        result += result * 0xb1721 + 2**132 - 1 >> 133;
      if (nx & 2**6 > 0)
        result += result * 0x58b91 + 2**132 - 1 >> 133;
      if (nx & 2**5 > 0)
        result += result * 0x2c5c8 + 2**132 - 1 >> 133;
      if (nx & 2**4 > 0)
        result += result * 0x162e4 + 2**132 - 1 >> 133;
      if (nx & 2**3 > 0)
        result += result * 0xb172 + 2**132 - 1 >> 133;
      if (nx & 2**2 > 0)
        result += result * 0x58b9 + 2**132 - 1 >> 133;
      if (nx & 2**1 > 0)
        result += result * 0x2c5d + 2**132 - 1 >> 133;
      if (nx & 2**0 > 0)
        result += result * 0x162e + 2**132 - 1 >> 133;

      //(nx >> 120) is always <= -1 due to SAR and require(nx<0)
      uint256 shift = uint256 (int256 (-1 - (nx >> 120)));
      result += (2**(shift-1))-1;
      result >>= shift;
      require (result <= uint256 (type(uint128).max));

      return result;
    }
  }
}
