// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import {Mech} from "../../src/account/mech/Mech.sol";

contract Sender is Mech {
    function isOperator(address) public view virtual override returns (bool) {
        return true;
    }
}
