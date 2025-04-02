// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.27;

interface IKimap {
    /// @dev Storage layout for a single entry in the map.
    /// If the data field is set, this entry is a fact/note:
    /// The tba/gene will be zero in that case.
    /// @param tba The token-bound account address associated with this entry.
    /// @param gene The address of the TBA implementation to be used for child entries.
    /// @param data The data stored in this entry (used for facts and notes).
    struct Entry {
        address tba;
        address gene;
        bytes data;
    }

    /*      ˗ˏˋ ♡ ˎˊ˗     */
    /*    Kimap errors    */
    /*      ˗ˏˋ ♡ ˎˊ˗     */

    error NoteMustBeginWithTilde(); ///// <- 0xa3b9ac95
    error FactMustBeginWithBang(); ////// <- 0x6ae27d4f
    error FailedToInitializeTBA(); ////// <- 0x5a714b1c
    error InvalidLabelCharacter(); ////// <- 0xe87f7f44
    error CannotCreate2Proxy(); ///////// <- 0x7080f645
    error NameAlreadyExists(); ////////// <- 0xd202940c
    error FactAlreadyExists(); ////////// <- 0xa542ed9c
    error GeneAlreadySet(); ///////////// <- 0xf3dda333
    error LabelTooShort(); ////////////// <- 0x280dacb6
    error LabelTooLong(); /////////////// <- 0x7d45f786
    error NotParent(); ////////////////// <- 0x3813fcca
    error EmptyFact(); ////////////////// <- 0x01b37205
    error OnlyZero(); /////////////////// <- 0xc6f4099f

    /*      ˗ˏˋ ♡ ˎˊ˗     */
    /*    Kimap events    */
    /*      ˗ˏˋ ♡ ˎˊ˗     */

    /// @notice Emitted when a new namespace entry is minted.
    /// @param parenthash The hash of the parent namespace entry.
    /// @param namehash The hash of the minted namespace entry's full path.
    /// @param labelhash The hash of only the label (the final entry in the path).
    /// @param label The label (the final entry in the path) of the new entry.
    event Mint(bytes32 indexed parenthash, bytes32 indexed namehash, bytes indexed labelhash, bytes label);

    /// @notice Emitted when a fact is created on an existing namespace entry.
    /// Facts are immutable and may only be written once. A fact label is
    /// prepended with an exclamation mark (!) to indicate that it is a fact.
    /// @param parenthash The hash of the parent namespace entry.
    /// @param namehash The hash of the newly created fact's full path.
    /// @param labelhash The hash of only the label (the final entry in the path).
    /// @param label The label of the fact.
    /// @param data The data stored at the fact.
    event Fact(bytes32 indexed parenthash, bytes32 indexed namehash, bytes indexed labelhash, bytes label, bytes data);

    /// @notice Emitted when a new note is created on an existing namespace entry.
    /// Notes are mutable. A note label is prepended with a tilde (~) to indicate
    /// that it is a note.
    /// @param parenthash The hash of the parent namespace entry.
    /// @param namehash The hash of the newly created note's full path.
    /// @param labelhash The hash of only the label (the final entry in the path).
    /// @param label The label of the note.
    /// @param data The data stored at the note.
    event Note(bytes32 indexed parenthash, bytes32 indexed namehash, bytes indexed labelhash, bytes label, bytes data);

    /// @notice Emitted when a gene is set for an existing namespace entry.
    /// A gene is a specific TBA implementation which will be applied to all
    /// sub-entries of the namespace entry.
    /// @param entry The namespace entry's namehash.
    /// @param gene The address of the TBA implementation.
    event Gene(bytes32 indexed entry, address indexed gene);

    /// @notice Emitted when the zeroth namespace entry is minted.
    /// Occurs exactly once at initialization.
    /// @param zeroTba The address of the zeroth TBA
    event Zero(address indexed zeroTba);

    /*       ˗ˏˋ ♡ ˎˊ˗       */
    /*    Kimap functions    */
    /*       ˗ˏˋ ♡ ˎˊ˗       */

    /// @notice Retrieves information about a specific namespace entry.
    /// @param namehash The namehash of the namespace entry to query.
    ///
    /// @return tba The address of the token-bound account associated
    /// with the entry.
    /// @return owner The address of the entry owner.
    /// @return data The note or fact bytes associated with the entry
    /// (empty if not a note or fact).
    function get(bytes32 namehash) external view returns (address tba, address owner, bytes memory data);

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
        returns (address tba);

    /// @notice Sets the gene for the calling namespace entry.
    /// @param _gene The address of the TBA implementation to set for all
    /// children of the calling namespace entry.
    function gene(address _gene) external;

    /// @notice Creates a new fact beneath the calling namespace entry.
    /// @param fact The fact label to create. Must be prepended with an exclamation mark (!).
    /// @param data The data to be stored at the fact.
    ///
    /// @return namehash The namehash of the newly created fact.
    function fact(bytes calldata fact, bytes calldata data) external returns (bytes32 namehash);

    /// @notice Creates a new note beneath the calling namespace entry.
    /// @param note The note label to create. Must be prepended with a tilde (~).
    /// @param data The data to be stored at the note.
    ///
    /// @return labelhash The namehash of the newly created note.
    function note(bytes calldata note, bytes calldata data) external returns (bytes32 labelhash);

    /// @notice Retrieves the token-bound account address of a namespace entry.
    /// @param entry The entry namehash for which to get the token-bound account.
    ///
    /// @return tba The token-bound account address of the namespace entry.
    function tbaOf(bytes32 entry) external view returns (address tba);

    /// @notice Builds a namehash given the parent namehash and a label.
    /// @param parenthash the namehash of the parent name entry.
    /// @param label the label with which to produce the child namehash
    ///
    /// @return namehash the namehash of the newly formed entry
    function leaf(bytes32 parenthash, bytes calldata label) external pure returns (bytes32 namehash);
}
