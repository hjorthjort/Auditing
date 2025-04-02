// SPDX-License-Identifier: MIT
pragma solidity ^0.8.x;
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {IXShadow} from "../interfaces/IXShadow.sol";
import {IGaugeV3} from "../CL/gauge/interfaces/IGaugeV3.sol";
import {INonfungiblePositionManager} from "../CL/periphery/interfaces/INonfungiblePositionManager.sol";
import {IShadowV3Factory} from "../CL/core/interfaces/IShadowV3Factory.sol";
import {IVoter} from "../interfaces/IVoter.sol";

contract ShadowExiter is Ownable {
    /// @notice accessHub address
    address public immutable accessHub;
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
        address _owner,
        address _accessHub,
        address _shadowV3Factory,
        address _nonfungiblePositionManager,
        address _voter,
        address _xshadow
    ) Ownable(_owner) {
        accessHub = _accessHub;
        shadowV3Factory = IShadowV3Factory(_shadowV3Factory);
        nonfungiblePositionManager = INonfungiblePositionManager(
            _nonfungiblePositionManager
        );
        voter = IVoter(_voter);
        xShadow = IXShadow(_xshadow);
    }
    /// @notice a function that allows instant claiming on behalf of a user's CL position
    function claimFromV3WithExit(uint256 _id, address _recipient) external {
        require(
            msg.sender == nonfungiblePositionManager.ownerOf(_id),
            "!owner"
        );
        /// @dev fetch the pool parameters from the NFP
        (
            address token0,
            address token1,
            int24 tickSpacing,
            ,
            ,
            ,
            ,
            ,
            ,

        ) = nonfungiblePositionManager.positions(_id);
        /// @dev fetch pool and gauge
        IGaugeV3 gauge = IGaugeV3(
            voter.gaugeForClPool(token0, token1, tickSpacing)
        );
        /// @dev create a temporary rewards array
        address[] memory r = new address[](1);
        /// @dev set the first element to the xShadow address
        r[0] = address(xShadow);
        /// @dev fetch pre-getReward balance
        uint256 pre = xShadow.balanceOf(address(this));
        /// @dev get xShadow rewards
        gauge.getReward(_id, r);
        /// @dev get post rewards claim balance
        uint256 post = xShadow.balanceOf(address(this));
        /// @dev calculate the difference
        uint256 diff = post - pre;
        /// @dev if there is a non-zero amount of shadow, send to the caller
        if (diff > 0) {
            /// @dev exit and transfer underlying to the caller
            shadow.transfer(_recipient, xShadow.exit(diff));
        }
    }

    /** Admin functions */

    function rescueNFT(uint256 _id, address _to) external onlyOwner {
        nonfungiblePositionManager.transferFrom(address(this), _to, _id);
    }

    function rescueToken(address _token) external onlyOwner {
        IERC20(_token).transfer(
            owner(),
            IERC20(_token).balanceOf(address(this))
        );
    }
}
