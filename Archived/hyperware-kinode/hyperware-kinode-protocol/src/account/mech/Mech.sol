//SPDX-License-Identifier: LGPL-3.0
pragma solidity ^0.8.27;

import {ECDSA} from "@openzeppelin-contracts-5.1.0/utils/cryptography/ECDSA.sol";
import {IERC165} from "@openzeppelin-contracts-5.1.0/utils/introspection/IERC165.sol";
import {IERC721} from "@openzeppelin-contracts-5.1.0/token/ERC721/IERC721.sol";
import {IERC1155Receiver} from "@openzeppelin-contracts-5.1.0/token/ERC1155/IERC1155Receiver.sol";
import {IERC1271} from "@openzeppelin-contracts-5.1.0/interfaces/IERC1271.sol";
import {IAccount} from "eth-infinitism-account-abstraction-0.7/contracts/interfaces/IAccount.sol";

import {Receiver} from "./Receiver.sol";
import {Account} from "./Account.sol";
import {IMech, IERC6551Executable} from "../../interfaces/IMech.sol";

/**
 * @dev This contract implements the authorization and signature validation for a mech. It's unopinionated about what it means to hold a mech. Child contract must define that by implementing the `isOperator` function.
 */
abstract contract Mech is IMech, Account, Receiver {
    // bytes4(keccak256("isValidSignature(bytes32,bytes)")
    bytes4 internal constant EIP1271_MAGICVALUE = 0x1626ba7e;

    /**
     * @dev Modifier to make a function callable only by the mech operator or the ERC4337 entry point contract
     */
    modifier onlyOperator() {
        if (!isOperator(msg.sender) && msg.sender != address(entryPoint())) {
            revert NotOperatorOrEntryPoint();
        }
        _;
    }

    /**
     * @dev Return if the passed address is authorized to sign on behalf of the mech, must be implemented by the child contract
     * @param signer The address to check
     */
    function isOperator(address signer) public view virtual returns (bool);

    /**
     * @dev Checks whether the signature provided is valid for the provided hash, complies with EIP-1271. A signature is valid if either:
     *  - It's a valid ECDSA signature by the mech operator
     *  - It's a valid EIP-1271 signature by the mech operator
     *  - It's a valid EIP-1271 signature by the mech itself
     * @param hash Hash of the data (could be either a message hash or transaction hash)
     * @param signature Signature to validate. Can be an ECDSA signature or a EIP-1271 contract signature (identified by v=0)
     */
    function isValidSignature(bytes32 hash, bytes memory signature)
        public
        view
        override(IERC1271, Account)
        returns (bytes4 magicValue)
    {
        bytes32 r;
        bytes32 s;
        uint8 v;
        (v, r, s) = _splitSignature(signature);

        if (v == 0) {
            // This is an EIP-1271 contract signature
            // The address of the contract is encoded into r
            address signingContract = address(uint160(uint256(r)));

            // The signature data to pass for validation to the contract is appended to the signature and the offset is stored in s
            bytes memory contractSignature;
            // solhint-disable-next-line no-inline-assembly
            assembly {
                contractSignature := add(add(signature, s), 0x20) // add 0x20 to skip over the length of the bytes array
            }

            // if it's our own signature, we recursively check if it's valid
            if (!isOperator(signingContract) && signingContract != address(this)) {
                return 0xffffffff;
            }

            return IERC1271(signingContract).isValidSignature(hash, contractSignature);
        } else {
            // This is an ECDSA signature
            if (isOperator(ECDSA.recover(hash, v, r, s))) {
                return EIP1271_MAGICVALUE;
            }
        }

        return 0xffffffff;
    }

    /// @dev Executes either a delegatecall or a call with provided parameters
    /// @param to Destination address.
    /// @param value Ether value.
    /// @param data Data payload.
    /// @param operation Operation type.
    /// @param txGas Gas to send for executing the meta transaction
    /// @return success boolean flag indicating if the call succeeded
    function _exec(address to, uint256 value, bytes calldata data, uint8 operation, uint256 txGas)
        internal
        returns (bool success, bytes memory returnData)
    {
        if (operation == 0) {
            (success, returnData) = to.call{gas: txGas, value: value}(data);
        } else if (operation == 1) {
            (success, returnData) = to.delegatecall{gas: txGas}(data);
        } else {
            revert("Invalid operation");
        }
    }

    /// @dev Allows the mech operator to execute arbitrary transactions
    /// @param to Destination address of transaction.
    /// @param value Ether value of transaction.
    /// @param data Data payload of transaction.
    /// @param operation Operation type of transaction.
    /// @param txGas Gas to send for executing the meta transaction, if 0 all left will be sent
    /// @return returnData Return data of the call
    function execute(address to, uint256 value, bytes calldata data, uint8 operation, uint256 txGas)
        public
        payable
        onlyOperator
        returns (bytes memory returnData)
    {
        bool success;
        (success, returnData) = _exec(to, value, data, operation, txGas == 0 ? gasleft() : txGas);

        if (!success) {
            // solhint-disable-next-line no-inline-assembly
            assembly {
                revert(add(returnData, 0x20), mload(returnData))
            }
        }
    }

    /// @dev Allows the mech operator to execute arbitrary transactions
    /// @param to Destination address of transaction.
    /// @param value Ether value of transaction.
    /// @param data Data payload of transaction.
    /// @param operation Operation type of transaction.
    /// @return returnData Return data of the call
    function execute(address to, uint256 value, bytes calldata data, uint8 operation)
        external
        payable
        onlyOperator
        returns (bytes memory returnData)
    {
        bool success;
        (success, returnData) = _exec(to, value, data, operation, gasleft());

        if (!success) {
            // solhint-disable-next-line no-inline-assembly
            assembly {
                revert(add(returnData, 0x20), mload(returnData))
            }
        }
    }

    /**
     * @dev Divides bytes signature into `uint8 v, bytes32 r, bytes32 s`.
     * @param signature The signature bytes
     */
    function _splitSignature(bytes memory signature) internal pure returns (uint8 v, bytes32 r, bytes32 s) {
        // The signature format is a compact form of:
        //   {bytes32 r}{bytes32 s}{uint8 v}
        // Compact means, uint8 is not padded to 32 bytes.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }
    }

    /// @dev Returns true if a given interfaceId is supported by this account. This method can be
    /// extended by an override
    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == type(IMech).interfaceId || interfaceId == type(IERC165).interfaceId
            || interfaceId == type(IAccount).interfaceId || interfaceId == type(IERC1271).interfaceId
            || interfaceId == type(IERC1155Receiver).interfaceId || interfaceId == type(IERC6551Executable).interfaceId;
    }
}
