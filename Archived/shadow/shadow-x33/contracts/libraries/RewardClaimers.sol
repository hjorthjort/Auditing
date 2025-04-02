// SPDX-License-Identifier: MIT
pragma solidity ^0.8.x;

import {INonfungiblePositionManager} from "../CL/periphery/interfaces/INonfungiblePositionManager.sol";
import {IGauge} from "../interfaces/IGauge.sol";
import {IGaugeV3} from "../CL/gauge/interfaces/IGaugeV3.sol";
import {IVoteModule} from "../interfaces/IVoteModule.sol";
import {IFeeDistributor} from "../interfaces/IFeeDistributor.sol";
import {Errors} from "contracts/libraries/Errors.sol";

/// @title RewardClaimers
/// @notice Reward claimers logic for Voter
/// @dev Used to reduce Voter contract size by moving all reward claiming logic to a library
library RewardClaimers {
    /// @dev function for claiming CL rewards with multiple ownership/access checks
    function claimClGaugeRewards(
        address nfpManager,
        address[] calldata _gauges,
        address[][] calldata _tokens,
        uint256[][] calldata _nfpTokenIds
    ) external {
        INonfungiblePositionManager nfpManagerContract = INonfungiblePositionManager(nfpManager);
        for (uint256 i; i < _gauges.length; ++i) {
            for (uint256 j; j < _nfpTokenIds[i].length; ++j) {
                require(
                    msg.sender == nfpManagerContract.ownerOf(_nfpTokenIds[i][j])
                        || msg.sender == nfpManagerContract.getApproved(_nfpTokenIds[i][j])
                        || nfpManagerContract.isApprovedForAll(nfpManagerContract.ownerOf(_nfpTokenIds[i][j]), msg.sender)
                );

                IGaugeV3(_gauges[i]).getRewardForOwner(_nfpTokenIds[i][j], _tokens[i]);
            }
        }
    }

    function claimGaugeV3RewardsAndExit(address[] calldata _gauges, address[][] calldata _tokens) external {
        // TODO:
    }

    /// @dev claims voting incentives batched
    function claimIncentives(
        address voteModule,
        address owner,
        address[] calldata _feeDistributors,
        address[][] calldata _tokens
    ) external {
        /// @dev restrict to authorized callers/admins
        require(IVoteModule(voteModule).isAdminFor(msg.sender, owner));

        for (uint256 i; i < _feeDistributors.length; ++i) {
            IFeeDistributor(_feeDistributors[i]).getRewardForOwner(owner, _tokens[i]);
        }
    }

    /// @dev for claiming a batch of legacy gauge rewards
    function claimRewards(address[] calldata _gauges, address[][] calldata _tokens) external {
        for (uint256 i; i < _gauges.length; ++i) {
            IGauge(_gauges[i]).getReward(msg.sender, _tokens[i]);
        }
    }

    /// @dev for users to exit legacy rewarded xshadow into shadow directly
    function claimLegacyRewardsAndExit(address[] calldata _gauges, address[][] calldata _tokens) external {
        for (uint256 i; i < _gauges.length; ++i) {
            IGauge(_gauges[i]).getRewardAndExit(msg.sender, _tokens[i]);
        }
    }

    /// @dev claim CL and legacy gauge rewards together
    function batchGetRewards(
        address nfpManager,
        address[] calldata _gauges,
        address[][] calldata _tokens,
        uint256[][] calldata _nfpId
    ) external {
        require(_gauges.length == _tokens.length && _gauges.length == _nfpId.length, "Invalid array length");

        INonfungiblePositionManager nfpManagerContract = INonfungiblePositionManager(nfpManager);

        for (uint256 i; i < _gauges.length; ++i) {
            /// @dev If no NFP IDs for this gauge, it's a legacy gauge
            if (_nfpId[i].length == 0) {
                IGauge(_gauges[i]).getReward(msg.sender, _tokens[i]);
            } else {
                /// @dev This is a v3 gauge - check ownership and claim for each NFP
                for (uint256 j; j < _nfpId[i].length; ++j) {
                    uint256 tokenId = _nfpId[i][j];
                    address tokenOwner = nfpManagerContract.ownerOf(tokenId);

                    require(
                        msg.sender == tokenOwner || msg.sender == nfpManagerContract.getApproved(tokenId)
                            || nfpManagerContract.isApprovedForAll(tokenOwner, msg.sender),
                        "Not authorized"
                    );

                    IGaugeV3(_gauges[i]).getRewardForOwner(tokenId, _tokens[i]);
                }
            }
        }
    }
}
