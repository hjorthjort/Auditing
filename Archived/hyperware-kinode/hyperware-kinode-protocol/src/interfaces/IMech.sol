//SPDX-License-Identifier: LGPL-3.0
pragma solidity ^0.8.27;

import {IERC1271} from "@openzeppelin-contracts-5.1.0/interfaces/IERC1271.sol";
import {IERC6551Executable} from "erc6551-reference-0.3.1/src/interfaces/IERC6551Executable.sol";
import {IAccount} from "eth-infinitism-account-abstraction-0.7/contracts/interfaces/IAccount.sol";

interface IMech is IAccount, IERC1271, IERC6551Executable {
    error NotOperatorOrEntryPoint();

    /// @dev Return if the passed address is authorized to sign on behalf of the mech, must be implemented by the child contract
    /// @param signer The address to check
    function isOperator(address signer) external view returns (bool);

    /// @dev Executes either a delegatecall or a call with provided parameters
    /// @param to Destination address.
    /// @param value Ether value.
    /// @param data Data payload.
    /// @param operation Operation type.
    /// @return returnData bytes The return data of the call
    function execute(address to, uint256 value, bytes calldata data, uint8 operation)
        external
        payable
        returns (bytes memory returnData);
}
