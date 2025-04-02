// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.27;

import {ECDSA} from "@openzeppelin-contracts-5.1.0/utils/cryptography/ECDSA.sol";
import {Initializable} from "@openzeppelin-contracts-upgradeable-5.1.0/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin-contracts-upgradeable-5.1.0/proxy/utils/UUPSUpgradeable.sol";
import {MessageHashUtils} from "@openzeppelin-contracts-5.1.0/utils/cryptography/MessageHashUtils.sol";

import {TokenBoundMech} from "./mech/TokenBoundMech.sol";
import {ERC721TokenBoundMech} from "./mech/ERC721TokenBoundMech.sol";
import {IKinoAccountMinter} from "../interfaces/IKinoAccountMinter.sol";
import {IKimap} from "../interfaces/IKimap.sol";

abstract contract KinoAccountMinterUpgradable is
    IKinoAccountMinter,
    ERC721TokenBoundMech,
    Initializable,
    UUPSUpgradeable
{
    using ECDSA for bytes32;

    bytes32 internal immutable _DOMAINSEPARATOR;

    IKimap internal immutable _KIMAP;

    mapping(address => uint256) internal _nonce;

    constructor(address _kimap) {
        _KIMAP = IKimap(_kimap);

        _DOMAINSEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract, bytes32 salt)"
                ),
                keccak256(bytes("EIP712KinoAccount")),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );
    }

    function initialize() external virtual initializer {
        __UUPSUpgradeable_init();
    }

    function kimap() external view virtual returns (IKimap) {
        return _KIMAP;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(TokenBoundMech) returns (bool) {
        return super.supportsInterface(interfaceId) || interfaceId == type(IKinoAccountMinter).interfaceId;
    }

    function getMessage(
        address to,
        bytes calldata name,
        bytes calldata initialization,
        address implementation,
        address signer
    ) public view returns (bytes32) {
        bytes32 hash =
            keccak256(abi.encodePacked(to, address(this), _nonce[signer], name, initialization, implementation, signer));

        return MessageHashUtils.toTypedDataHash(_DOMAINSEPARATOR, hash);
    }

    function mint(address to, bytes calldata name, bytes calldata initialization, address implementation)
        external
        payable
        returns (address tba)
    {
        return _mint(to, name, initialization, implementation);
    }

    function mintBySignature(
        address to,
        bytes calldata name,
        bytes calldata initialization,
        address implementation,
        Signature calldata signature
    ) external virtual returns (address tba) {
        bytes32 message = getMessage(to, name, initialization, implementation, signature.signer);

        bytes32 messageHash = MessageHashUtils.toEthSignedMessageHash(message);

        address recoverAddress = messageHash.recover(signature.v, signature.r, signature.s);
        if (recoverAddress != signature.signer) {
            revert InvalidSignature(recoverAddress, signature.signer);
        }

        _nonce[recoverAddress]++;
        return _mint(to, name, initialization, implementation);
    }

    function _mint(address to, bytes calldata name, bytes calldata initialization, address implementation)
        internal
        virtual
        returns (address tba)
    {
        return _KIMAP.mint(to, name, initialization, implementation);
    }

    function _authorizeUpgrade(address newImplementation) internal virtual override onlyOperator {}
}
