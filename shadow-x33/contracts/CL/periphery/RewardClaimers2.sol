// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.x;

import {GaugeV3} from "contracts/CL/gauge/GaugeV3.sol";
import {IGaugeV3} from "../gauge/interfaces/IGaugeV3.sol";
import {IVoteModule} from "contracts/VoteModule.sol";
import {IFeeDistributor} from "contracts/interfaces/IFeeDistributor.sol";
import {IPair} from "contracts/interfaces/IPair.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IRouter} from "contracts/interfaces/IRouter.sol";
import {IShadowV3Factory} from "../core/interfaces/IShadowV3Factory.sol";
import {INonfungiblePositionManager} from "../periphery/interfaces/INonfungiblePositionManager.sol";
import {IVoter} from "contracts/interfaces/IVoter.sol";
import {IXShadow} from "contracts/interfaces/IXShadow.sol";
import {IGauge} from "contracts/Gauge.sol";

contract RewardClaimers2 {
    /// @notice legacy router address
    address public legacyRouter;
    /// @notice access hub contract address
    address public accessHub;
    /// @notice SHADOW token
    IERC20 public immutable shadow;
    /// @notice v3 factory
    IShadowV3Factory public immutable shadowV3Factory;
    /// @notice nfp contract
    INonfungiblePositionManager public immutable nonfungiblePositionManager;
    /// @notice voter contract
    IVoter public immutable voter;
    /// @notice xshadow contract
    IXShadow public immutable xShadow;

    constructor(
        address _legacyRouter,
        address _accessHub,
        address _shadowV3Factory,
        address _nonfungiblePositionManager,
        address _voter,
        address _xshadow,
        address _shadow
    ) {
        legacyRouter = _legacyRouter;
        accessHub = _accessHub;
        shadowV3Factory = IShadowV3Factory(_shadowV3Factory);
        nonfungiblePositionManager = INonfungiblePositionManager(_nonfungiblePositionManager);
        voter = IVoter(_voter);
        xShadow = IXShadow(_xshadow);
        shadow = IERC20(_shadow);
    }

    //////////////////////////////
    //// Incentives Helpers //////
    //////////////////////////////

    /// @notice try to unwrap LP token to token0/1
    /// @param token LP token address
    /// @return isLP bool if its a LP token
    /// @return tokenA token0 address
    /// @return tokenB token1 address
    function _tryUnwrapLP(address token) internal returns (bool isLP, address tokenA, address tokenB) {
        try IPair(token).token0() returns (address token0) {
            address token1 = IPair(token).token1();
            uint256 lpBalance = IERC20(token).balanceOf(address(this));

            if (lpBalance > 0) {
                // approve legacy router to spend LP tokens
                IERC20(token).approve(legacyRouter, lpBalance);
                // remove liquidity
                IRouter(legacyRouter).removeLiquidity(
                    token0,
                    token1,
                    IPair(token).stable(),
                    lpBalance,
                    0, // amountAMin
                    0, // amountBMin
                    address(this),
                    block.timestamp
                );

                return (true, token0, token1);
            }
        } catch {
            return (false, address(0), address(0));
        }
    }

    /// @notice claim legacy incentives and unwrap LP token to token0/1
    /// @param _feeDistributors fee distributor addresses
    /// @param _rewardTokens reward token addresses
    function claimLegacyIncentives(address[] memory _feeDistributors, address[][] memory _rewardTokens) public {
        for (uint256 i = 0; i < _feeDistributors.length; i++) {
            // claim all tokens for this distributor
            IFeeDistributor(_feeDistributors[i]).getReward(msg.sender, _rewardTokens[i]);
            // process each reward token
            for (uint256 j = 0; j < _rewardTokens[i].length; j++) {
                address rewardToken = _rewardTokens[i][j];
                // try to unwrap if it's a LP token
                (bool isLP, address tokenA, address tokenB) = _tryUnwrapLP(rewardToken);
                if (isLP) {
                    // transfer unwrapped tokens to caller
                    uint256 balanceA = IERC20(tokenA).balanceOf(address(this));
                    uint256 balanceB = IERC20(tokenB).balanceOf(address(this));

                    if (balanceA > 0) IERC20(tokenA).transfer(msg.sender, balanceA);
                    if (balanceB > 0) IERC20(tokenB).transfer(msg.sender, balanceB);
                } else {
                    // transfer regular token to caller
                    uint256 balance = IERC20(rewardToken).balanceOf(address(this));
                    if (balance > 0) IERC20(rewardToken).transfer(msg.sender, balance);
                }
            }
        }
    }

    //////////////////////////////
    //// Gauge Reward Helpers ////
    //////////////////////////////
    function claimLegacyGaugeRewardsAndExit(address[] memory _gauges, address[][] memory _rewardTokens) external {
        for (uint256 i = 0; i < _gauges.length; i++) {
            IGauge(_gauges[i]).getRewardAndExit(msg.sender, _rewardTokens[i]);
        }
    }

    /// @notice a function that allows instant claiming on behalf of a user's CL position
    /// @param _nfpIds Array of nfpIds per gauge
    /// @param _gauges Array of gauge addresses
    /// @param _rewardTokens Array of rewardTokens per gauge
    /// @dev xshadow is claimed internally and sent to the caller, so _rewardTokens should never include xshadow
    function claimCLGaugeRewardsAndExit(
        address[] memory _gauges,
        address[][] memory _rewardTokens,
        uint256[][] memory _nfpIds
    ) external {
        uint256 xShadowBalanceBefore = xShadow.balanceOf(address(this));

        /// @dev claim xshadow to this contract
        address[] memory xshadowRewardToken = new address[](1);
        xshadowRewardToken[0] = address(xShadow);

        /// @dev loop claim all xshadow from all nfpIds
        for (uint256 i = 0; i < _gauges.length; i++) {
            for (uint256 j = 0; j < _nfpIds[i].length; j++) {
                IGaugeV3(_gauges[i]).getReward(_nfpIds[i][j], xshadowRewardToken);
            }
        }
        uint256 xShadowBalanceAfter = xShadow.balanceOf(address(this));
        uint256 diff = xShadowBalanceAfter - xShadowBalanceBefore;

        /// @dev fetch only the difference (in case contract already had xshadow balance)
        /// @dev exit and transfer underlying to the caller
        if (diff > 0) {
            shadow.transfer(msg.sender, xShadow.exit(diff));
        }

        /// @dev claim all other rewards (sent directly to the caller)
        voter.claimClGaugeRewards(_gauges, _rewardTokens, _nfpIds);
    }

    /////////////////////////////
    //////  Rescue Helpers //////
    /////////////////////////////

    /// @notice Rescue NFT from the contract
    /// @param _id NFT token ID to rescue
    /// @param _to Address to send the NFT to
    function rescueNFT(uint256 _id, address _to) external {
        require(msg.sender == accessHub, "NOT_ACCESSHUB");
        nonfungiblePositionManager.transferFrom(address(this), _to, _id);
    }

    /// @notice Rescue any stuck tokens from the contract
    /// @param _token Token address to rescue
    /// @param _amount Amount of tokens to rescue
    /// @dev Only callable by AccessHub
    function rescueToken(address _token, uint256 _amount) external {
        require(msg.sender == accessHub, "NOT_ACCESSHUB");
        // transfer the tokens to the caller (AccessHub)
        IERC20(_token).transfer(msg.sender, _amount);
    }
}
