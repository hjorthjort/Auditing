// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.27;

import {KinoAccountCommitMinter} from "./KinoAccountCommitMinter.sol";

contract KinoAccount9CharCommitMinter is KinoAccountCommitMinter {
    constructor(address _kimap, uint256 _minCommitAge, uint256 _maxCommitAge)
        KinoAccountCommitMinter(_kimap, _minCommitAge, _maxCommitAge)
    {}

    function _mint(address to, bytes calldata name, bytes calldata initialization, address implementation)
        internal
        override
        returns (address tba)
    {
        if (name.length < 9) revert("Label too short");
        return super._mint(to, name, initialization, implementation);
    }
}
