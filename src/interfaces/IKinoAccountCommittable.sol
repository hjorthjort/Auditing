// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.27;

interface IKinoAccountCommittable {
    error CommitTooOld();
    error CommitTooNew();
    error CommitNotFound();
    error UnexpiredCommitExists();

    /// @notice Privately commit to a specific name by hashing it along with the
    /// sender's address. A commit is valid for a certain period of time, found
    /// by reading maxCommitAge(). While the commit is valid, the sender can mint.
    /// @param _commit The keccak256 hash of the name+sender to commit to. Can be
    /// obtained by calling getCommitHash.
    function commit(bytes32 _commit) external;

    /// @notice Get the keccak256 hash of a name+sender.
    /// @param name The name to hash.
    /// @param sender The sender's address to hash.
    /// @return The keccak256 hash of the name+sender.
    function getCommitHash(bytes memory name, address sender) external pure returns (bytes32);

    /// @notice Get an existing commit's expiration timestamp.
    /// @param _commit The keccak256 hash of the name to get the commit for.
    /// @return The commit for the name, containing the expiration timestamp and the
    /// sender.
    function getCommit(bytes32 _commit) external view returns (uint256);
}
