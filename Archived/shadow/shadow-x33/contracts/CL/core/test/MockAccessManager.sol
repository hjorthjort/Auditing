// SPDX-License-Identifier: MIT
pragma solidity ^0.8.x;

contract MockAccessManager {
    function canCall(address, address, bytes4) public pure returns (bool immediate, uint32 delay) {
        immediate = true;
        delay = 0;
    }
}
