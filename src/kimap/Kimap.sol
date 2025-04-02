// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.27;

import {UUPSUpgradeable} from "@openzeppelin-contracts-upgradeable-5.1.0/proxy/utils/UUPSUpgradeable.sol";
import {ERC721Upgradeable} from "@openzeppelin-contracts-upgradeable-5.1.0/token/ERC721/ERC721Upgradeable.sol";
import {ERC721Holder} from "@openzeppelin-contracts-5.1.0/token/ERC721/utils/ERC721Holder.sol";
import {ERC6551AccountLib} from "erc6551-reference-0.3.1/src/lib/ERC6551AccountLib.sol";
import {AccessControlUpgradeable} from "@openzeppelin-contracts-upgradeable-5.1.0/access/AccessControlUpgradeable.sol";

import {IKimap} from "../interfaces/IKimap.sol";

import {KinoAccount} from "../account/KinoAccount.sol";
import {KinoAccountProxy} from "../account/KinoAccountProxy.sol";
import {KinoAccountMinter} from "../account/KinoAccountMinter.sol";
import {IKinoAccountMinter} from "../interfaces/IKinoAccountMinter.sol";
import {KimapStorage} from "./KimapStorage.sol";

contract Kimap is IKimap, AccessControlUpgradeable, UUPSUpgradeable, ERC721Upgradeable, ERC721Holder, KimapStorage {
    /// @notice Modifier to check if a label is a valid name.
    /// A valid kimap name must only contain:
    /// - lowercase ASCII letters
    /// - numbers
    /// - hyphens (-)
    /// Offchain interfaces should still validate names before submitting
    /// and after reading from kimap. This is also true for notes and facts.
    modifier isName(bytes memory label) {
        _isValidLabel(label, 0);
        _;
    }

    /// @notice Modifier to check if a label is valid for a note.
    modifier isNote(bytes memory label) {
        if (label[0] != 0x7E) revert NoteMustBeginWithTilde();
        _isValidLabel(label, 1);
        _;
    }

    /// @notice Modifier to check if a label is valid for afact.
    modifier isFact(bytes memory label) {
        if (label[0] != 0x21) revert FactMustBeginWithBang();
        _isValidLabel(label, 1);
        _;
    }

    /// @dev Internal function to check if a label is valid for a name.
    /// @param label the label to check.
    /// @param offset the offset to start checking from.
    /// Reverts if the label is not valid for a name.
    function _isValidLabel(bytes memory label, uint256 offset) internal pure {
        uint256 len = label.length;
        if (len == offset) revert LabelTooShort();
        // name length must be less than 64 characters (including ~/! prefix)
        else if (len >= 64) revert LabelTooLong();

        for (uint256 i = offset; i < len; i++) {
            bytes1 char = label[i];
            if (
                // permitted characters: -0123456789abcdefghijklmnopqrstuvwxyz
                !((char >= 0x30 && char <= 0x39) || (char >= 0x61 && char <= 0x7A) || char == 0x2D)
            ) revert InvalidLabelCharacter();
        }
    }

    /// @notice Internal authorization that asserts only the parent
    /// token bound account may call a function on a kimap entry.
    /// @dev Asserts the caller is the parent TBA and returns
    /// the name entry of the caller for later use.
    ///
    /// @return entry the namehash of the parent entry.
    function _callerIsParent() internal view returns (bytes32 entry) {
        (,, uint256 token) = ERC6551AccountLib.token(msg.sender);
        bytes32 namehash = bytes32(token);
        if (map[namehash].tba != msg.sender) revert NotParent();
        return namehash;
    }

    /// @notice Initializes the kimap contract. Creates a "root entry", which
    /// has the namehash of 0 and allows its owner to operate its account.
    /// @param _admin The address of the owner of the root entry account.
    /// for the root entry token-bound account.
    function initialize(address _admin) public initializer {
        __ERC721_init("Kimap", "KIMAP");
        __AccessControl_init();

        // The address of the implementation of default KinoAccountMinter
        address zerothTbaImplementation = address(new KinoAccount());

        address zeroTba = _mint(_admin, bytes32(0), zerothTbaImplementation, false, hex"");
        _revokeRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        emit Zero(zeroTba);
    }

    /// @notice Function to authorize upgrades to the kimap contract.
    function _authorizeUpgrade(address) internal view override onlyRole(DEFAULT_ADMIN_ROLE) {}

    /// @notice Retrieves information about a specific namespace entry.
    /// @param namehash The namehash of the namespace entry to query.
    ///
    /// @return tba The address of the token-bound account associated
    /// with the entry.
    /// (zero if note or fact).
    /// @return owner The address of the entry owner.
    /// (zero if note or fact).
    /// @return data The note or fact bytes associated with the entry
    /// (empty if not a note or fact).
    function get(bytes32 namehash) external view returns (address, address, bytes memory) {
        Entry memory entry = map[namehash];
        if (entry.tba == address(0)) {
            return (address(0), address(0), entry.data);
        } else {
            return (entry.tba, ownerOf(uint256(namehash)), entry.data);
        }
    }

    /// @notice Mints a new namespace entry and creates a token-bound account for
    /// it. Must be called by a parent namespace entry token-bound account.
    /// @param to The address to own the new namespace entry.
    /// @param label The label to mint beneath the calling parent entry.
    /// @param initialization Initialization calldata applied to the new
    /// minted entry's token-bound account.
    /// @param implementation The address of the implementation contract for
    /// the token-bound account: this will be overriden by the gene if the
    /// parent entry has one set.
    ///
    /// @return tba The address of the new entry's token-bound account.
    function mint(address to, bytes calldata label, bytes calldata initialization, address implementation)
        external
        isName(label)
        returns (address tba)
    {
        // in order to mint a new entry, must always be calling from parent TBA
        // callerIsParent enforces this
        bytes32 parent = _callerIsParent();

        // create the child entry's namehash
        bytes32 child = leaf(parent, label);

        bool setGene = false;

        // if the parent has a gene (a specific TBA implementation)
        // set the TBA implementation of the child to the parent's gene
        // and set the child's gene to the parent's gene
        if (map[parent].gene != address(0)) {
            implementation = map[parent].gene;
            setGene = true;
        }

        // emit mint event **before** calling mint-with-initializer,
        // because the initialization may emit note/fact events which
        // should appear **after** the mint event in logs.
        emit Mint(parent, child, label, label);

        tba = _mint(to, child, implementation, setGene, initialization);
    }

    function _mint(address to, bytes32 namehash, address implementation, bool setGene, bytes memory initialization)
        internal
        returns (address tba)
    {
        if (map[namehash].tba != address(0)) revert NameAlreadyExists();

        tba = ERC6551_REGISTRY.createAccount(
            address(new KinoAccountProxy{salt: namehash}(address(this))),
            // ^^^ the implementation is a basic 1967 proxy contract, which
            // allows us to have a counterfactual address while permitting
            // any given account to have custom behavior
            namehash, // namehash used as salt
            block.chainid,
            address(this), // kimap is the token contract for all namespace TBAs
            uint256(namehash) // namehash used as token id
        );

        // set node's tba and set this contract as the token's
        // owner for potential initialization call, which will
        // be authenticated according to the token owner.
        map[namehash] = Entry(tba, setGene ? implementation : address(0), bytes(""));

        // mint the actual ERC721 token
        _mint(address(this), uint256(namehash));

        // call the token-bound account's initialize function
        (bool success,) =
            tba.call(abi.encodeWithSelector(KinoAccountProxy.initialize.selector, implementation, initialization));
        if (!success) {
            revert FailedToInitializeTBA();
        }

        _safeTransfer(address(this), to, uint256(namehash));
    }

    /// @notice Public function callable by a name entry's
    /// token bound account in order to create a gene entry.
    /// A gene entry defines the token bound account implementation
    /// that will be used for all entries in the tree beneath this
    /// name entry. For instance, if gene() is called for `.kino`,
    /// then `sub.kino` as well as `sub.sub.kino` will have the same
    /// implementation, and so on.
    /// @dev Must be called by the associated entry's token bound account.
    /// @param _gene The address of the TBA implementation to set for all
    /// children of the calling namespace entry.
    function gene(address _gene) external {
        // in order to set a gene, must always be calling from parent TBA
        bytes32 parent = _callerIsParent();
        if (map[parent].gene != address(0)) {
            revert GeneAlreadySet();
        }
        map[parent].gene = _gene;
        emit Gene(parent, _gene);
    }

    /// @notice Creates a new fact beneath the calling namespace entry.
    /// @dev Must be called by a namespace entry's TBA, and the entry
    /// must not already have a fact with the same label.
    /// @param _fact The fact label to create. Must be prepended with an
    /// exclamation mark (!).
    /// @param _data The data to be stored at the fact.
    ///
    /// @return namehash The namehash of the newly created fact.
    function fact(bytes calldata _fact, bytes calldata _data) external isFact(_fact) returns (bytes32 namehash) {
        // in order to mint a new fact, must always be calling from parent TBA
        bytes32 parent = _callerIsParent();
        // produce the namehash of the new fact
        namehash = leaf(parent, _fact);
        if (map[namehash].data.length != 0) revert FactAlreadyExists();
        if (_data.length == 0) revert EmptyFact();
        map[namehash].data = _data;
        emit Fact(parent, namehash, _fact, _fact, _data);
    }

    /// @notice Creates a new note beneath the calling namespace entry.
    /// @dev Must be called by a namespace entry's TBA.
    /// @param _note The note label to create. Must be prepended with a tilde (~).
    /// @param _data The data to be stored at the note.
    ///
    /// @return namehash The namehash of the newly created note.
    function note(bytes calldata _note, bytes calldata _data) external isNote(_note) returns (bytes32 namehash) {
        // in order to mint a new note, must always be calling from parent TBA
        bytes32 parent = _callerIsParent();
        // produce the namehash of the new note
        namehash = leaf(parent, _note);
        // notes are mutable, so any existing data at this note will be overwritten
        map[namehash].data = _data;
        emit Note(parent, namehash, _note, _note, _data);
    }

    /// @notice Retrieves the token-bound account address of a namespace entry.
    /// @param entry The entry namehash for which to get the token-bound account.
    ///
    /// @return tba The token-bound account address of the namespace entry.
    function tbaOf(bytes32 entry) public view returns (address tba) {
        return map[entry].tba;
    }

    /// @notice Builds a namehash given the parent namehash and a label.
    /// @param parenthash the namehash of the parent name entry.
    /// @param label the label with which to produce the child namehash
    ///
    /// @return namehash the namehash of the newly formed entry
    function leaf(bytes32 parenthash, bytes calldata label) public pure returns (bytes32 namehash) {
        assembly {
            let ptr := mload(0x40)
            mstore(0x40, add(ptr, add(label.length, 0x20)))
            calldatacopy(ptr, label.offset, label.length)

            let labelhash := keccak256(ptr, label.length)

            let combo := mload(0x40)
            mstore(combo, parenthash)
            mstore(add(combo, 0x20), labelhash)

            namehash := keccak256(combo, 0x40)
        }
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Upgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
