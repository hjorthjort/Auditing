// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import {KinoAccountMinter} from "../../src/account/KinoAccountMinter.sol";

contract KinoAccountGeneTester is KinoAccountMinter {
    bool public immutable _gene;

    constructor(address _kimap, bool value) KinoAccountMinter(_kimap) {
        _gene = value;
    }

    function gene() public view returns (bool) {
        return _gene;
    }
}
