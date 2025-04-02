// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.27;

import {KinoAccountMinterUpgradable} from "./KinoAccountMinterUpgradable.sol";
import {IKinoAccountCommittable} from "../interfaces/IKinoAccountCommittable.sol";

contract KinoAccountCommitMinter is IKinoAccountCommittable, KinoAccountMinterUpgradable {
    uint256 public immutable minCommitAge;
    uint256 public immutable maxCommitAge;

    mapping(bytes32 => uint256) internal _commits;

    constructor(address _kimap, uint256 _minCommitAge, uint256 _maxCommitAge) KinoAccountMinterUpgradable(_kimap) {
        minCommitAge = _minCommitAge;
        maxCommitAge = _maxCommitAge;
    }

    function commit(bytes32 _commit) external {
        if (_commits[_commit] >= block.timestamp) {
            revert UnexpiredCommitExists();
        } else {
            _commits[_commit] = block.timestamp + maxCommitAge;
        }
    }

    function getCommitHash(bytes memory name, address sender) external pure returns (bytes32) {
        return _getCommitHash(name, sender);
    }

    function _getCommitHash(bytes memory name, address sender) internal pure returns (bytes32) {
        return keccak256(abi.encode(name, sender));
    }

    function getCommit(bytes32 _commit) external view returns (uint256) {
        return _commits[_commit];
    }

    function _mint(address to, bytes calldata name, bytes calldata initialization, address implementation)
        internal
        virtual
        override
        returns (address tba)
    {
        uint256 commitExpiration = _commits[_getCommitHash(name, msg.sender)];

        // if the commit is empty, the sender has not committed to the name
        if (commitExpiration == 0) {
            revert CommitNotFound();
        }
        // if the commit is less than MIN_COMMIT_AGE old, it's too new
        if (commitExpiration - maxCommitAge + minCommitAge >= block.timestamp) {
            revert CommitTooNew();
        }
        // if the commit expiration block is in the past, it's too old
        if (commitExpiration < block.timestamp) {
            revert CommitTooOld();
        }

        return _KIMAP.mint(to, name, initialization, implementation);
    }
}
