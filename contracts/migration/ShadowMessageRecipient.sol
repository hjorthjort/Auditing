// SPDX-License-Identifier: MIT
pragma solidity ^0.8.x;

import {OApp, Origin, MessagingFee} from "@layerzerolabs/oapp-evm/contracts/oapp/OApp.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IShadowMessageRecipient} from "../migration/interfaces/IShadowMessageRecipient.sol";
import {IXShadow} from "../interfaces/IXShadow.sol";
/// @title Shadow's x-chain messaging receiver contract, utilizing LayerZero and selected, secure DVNs
contract ShadowMessageRecipient is IShadowMessageRecipient, OApp {
    bool public paused = true;
    IXShadow public xShadow;

    /// @inheritdoc IShadowMessageRecipient
    mapping(address => uint256) public claimable;
    /// @inheritdoc IShadowMessageRecipient
    mapping(address => uint256) public userMigratedTotal;

    constructor(
        address _endpoint,
        address _owner
    ) OApp(_endpoint, _owner) Ownable(_owner) {}

    /// @inheritdoc IShadowMessageRecipient
    function claim() external {
        require(!paused, "paused");
        /// @dev grab claimable from mapping
        uint256 claimableAmount = claimable[msg.sender];
        /// @dev ensure there's a balance
        require(claimableAmount != 0, "no allocation");

        require(
            xShadow.balanceOf(address(this)) >= claimableAmount,
            "contract needs refilling"
        );
        /// @dev zero out the user's claimable balance
        claimable[msg.sender] = 0;
        /// @dev send the xShadow
        xShadow.transfer(msg.sender, claimableAmount);
    }

    /// @inheritdoc IShadowMessageRecipient
    function rescue(address _to) external onlyOwner {
        xShadow.transfer(_to, xShadow.balanceOf(address(this)));
    }

    /// @inheritdoc IShadowMessageRecipient
    function setXShadow(address _xShadow) external onlyOwner {
        require(address(xShadow) == address(0), "already initialized");
        paused = false;
        xShadow = IXShadow(_xShadow);
    }

    /**
     * @dev Called when data is received from the protocol. It overrides the equivalent function in the parent contract.
     * Protocol messages are defined as packets, comprised of the following parameters.
     * @param _origin A struct containing information about where the packet came from.
     * @param _guid A global unique identifier for tracking the packet.
     * @param payload Encoded message.
     */
    function _lzReceive(
        Origin calldata _origin,
        bytes32 _guid,
        bytes calldata payload,
        address, // Executor address as specified by the OApp.
        bytes calldata // Any extra data or options to trigger on receipt.
    ) internal override {
        /// @dev decode the payload to get the message
        LocalParameters memory data = abi.decode(payload, (LocalParameters));

        /// @dev sanity check for message being decoded
        if (data.amountMigrated > 0 && data.user != address(0)) {
            /// @dev add to migration mapping
            claimable[data.user] += data.amountMigrated;
            userMigratedTotal[data.user] += data.amountMigrated;
            return;
        } else {
            /// @dev terminate or handle non-operating
            return;
        }
    }
}
