// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.27;

import {KinoAccountMinterUpgradable} from "./KinoAccountMinterUpgradable.sol";
import {IKinoAccountPermissioned} from "../../src/interfaces/IKinoAccountPermissioned.sol";

contract KinoAccountPermissionedMinter is IKinoAccountPermissioned, KinoAccountMinterUpgradable {
    // Errors
    error InsufficientAllowance(address who);

    mapping(address => uint256) internal _allowances;

    // Gaps
    uint256[49] __gaps;

    constructor(address _kimap) KinoAccountMinterUpgradable(_kimap) {}

    /// @notice Authorize a minter to mint a specific number of sub-entries
    function auth(address who, uint256 _allowance) external onlyOperator {
        _allowances[who] = _allowance;
    }

    function deauth(address who) external onlyOperator {
        _allowances[who] = 0;
    }

    function allowance(address who) external view returns (uint256) {
        return _allowances[who];
    }

    function _mint(address to, bytes calldata name, bytes calldata initialization, address implementation)
        internal
        override
        returns (address tba)
    {
        if (_allowances[msg.sender] < 1) {
            revert InsufficientAllowance(msg.sender);
        }
        _allowances[msg.sender] -= 1;
        return _KIMAP.mint(to, name, initialization, implementation);
    }
}
