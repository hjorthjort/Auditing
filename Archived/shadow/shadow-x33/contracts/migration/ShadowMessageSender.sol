// SPDX-License-Identifier: MIT
pragma solidity ^0.8.x;

import {OApp, Origin, MessagingFee} from "@layerzerolabs/oapp-evm/contracts/oapp/OApp.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IShadowMessageSender} from "../migration/interfaces/IShadowMessageSender.sol";
import {OptionsBuilder} from "@layerzerolabs/oapp-evm/contracts/oapp/libs/OptionsBuilder.sol";

contract ShadowMessageSender is IShadowMessageSender, OApp {
    using OptionsBuilder for bytes;

    /// @notice reciept addresses on fantom
    IERC20 public constant RSHADOW_V1 = IERC20(0xD7855D9E05a1721d3d9273f33BFb18d72aBb1Cf3);
    IERC20 public constant RSHADOW_V2 = IERC20(0x52E63608d58Ce4aAf46e367d298867F485E7131d);

    /// @notice mapping of users on fantom who migrated
    mapping(address => uint256) public userToMigrated;

    constructor(address _endpoint, address _owner) OApp(_endpoint, _owner) Ownable(_owner) {}

    /// @inheritdoc IShadowMessageSender
    function toSonic() external payable {
        /// @dev requires the user approves rshadow v1/v2 to the contract beforehand
        LocalParameters memory localPayload = _versionHandler(msg.sender);
        /// @dev encodes the cross-chain message
        bytes memory _payload = abi.encode(localPayload);

        /**
         * Layerzero gas specs
         */
        uint128 gas = 500_000;
        bytes memory options = OptionsBuilder.newOptions().addExecutorLzReceiveOption(gas, 0);

        /// @dev internal bridge call
        _lzSend(30332, _payload, options, MessagingFee(msg.value, 0), payable(msg.sender));
    }

    /// @dev internal version handler, compressing functionality to be encoding on a x-chain message
    function _versionHandler(address _user) internal returns (LocalParameters memory relayMessage) {
        uint256 combinedBalance;

        uint256 _balv1 = RSHADOW_V1.balanceOf(_user);
        uint256 _balv2 = RSHADOW_V2.balanceOf(_user);

        if (_balv1 > 0) {
            require(RSHADOW_V1.transferFrom(_user, address(this), _balv1), "V1 Collection Failed");
            combinedBalance += _balv1;
        }

        if (_balv2 > 0) {
            require(RSHADOW_V2.transferFrom(_user, address(this), _balv2), "V2 Collection Failed");
            combinedBalance += _balv2;
        }

        /// @dev ensure the user has a balance of either version
        require(combinedBalance > 0, "no balance");
        /// @dev update the mapping on fantom
        userToMigrated[_user] += combinedBalance;
        /// @dev return the parameters for encoding
        return LocalParameters(_user, combinedBalance);
    }

    /// @dev collect tokens from migration for burning
    function collect(address _to) external onlyOwner {
        uint256 _balv1 = RSHADOW_V1.balanceOf(address(this));
        if (_balv1 > 0) {
            RSHADOW_V1.transfer(_to, _balv1);
        }
        uint256 _balv2 = RSHADOW_V2.balanceOf(address(this));
        if (_balv2 > 0) {
            RSHADOW_V2.transfer(_to, _balv2);
        }
    }

    /// @dev override
    function _lzReceive(
        Origin calldata _origin,
        bytes32 _guid,
        bytes calldata _message,
        address _executor,
        bytes calldata _extraData
    ) internal virtual override {}
}
