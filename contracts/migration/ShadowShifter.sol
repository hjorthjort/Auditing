// SPDX-License-Identifier: MIT
pragma solidity ^0.8.x;

import {IXShadow} from "../interfaces/IXShadow.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {Errors} from "contracts/libraries/Errors.sol";

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";

/// @title ShadowShifter - Token Migration Contract
/// @notice This contract facilitates the silent migration of SHADOW and xSHADOW tokens to their new versions
/// @dev Inherits from Ownable for access control and Pausable for emergency stops
contract ShadowShifter is Ownable, Pausable {
    address public reservoir;
    /// @notice The original SHADOW token contract
    IERC20 public immutable SHADOW;
    /// @notice The original xSHADOW token contract
    IXShadow public immutable XSHADOW;

    /// @notice The new version of the SHADOW token contract
    IERC20 public immutable NEW_SHADOW;
    /// @notice The new version of the xSHADOW token contract
    IXShadow public immutable NEW_XSHADOW;

    /// @notice Mapping to track migration state for each user
    /// @dev Stores the amount of tokens migrated by each user
    mapping(address => MigrationState) public userMigrationData;

    /// @notice Structure to hold migration state for a user
    /// @dev Tracks both SHADOW and xSHADOW migration amounts
    struct MigrationState {
        uint256 amountShadow; // Amount of SHADOW tokens migrated
        uint256 amountXShadow; // Amount of xSHADOW tokens migrated
    }

    /// @notice Emitted when tokens are migrated
    /// @param token Address of the token being migrated (SHADOW or xSHADOW)
    /// @param user Address of the user performing the migration
    /// @param amount Amount of tokens being migrated
    event Changed(address token, address user, uint256 amount);

    event Collected(address reservoir, address token, uint256 amount);

    /// @notice Modifier to ensure function can only be called when contract is not paused
    modifier whileNotPaused() {
        require(!paused(), "paused");
        _;
    }

    /// @notice Contract constructor
    /// @dev Initializes the contract with addresses of original token contracts
    /// @param _shadow Address of the original SHADOW token contract
    /// @param _xshadow Address of the original xSHADOW token contract
    constructor(address _shadow, address _xshadow, address _new_shadow, address _new_xshadow)
        Ownable(msg.sender)
        Pausable()
    {
        SHADOW = IERC20(_shadow);
        XSHADOW = IXShadow(_xshadow);

        NEW_SHADOW = IERC20(_new_shadow);
        NEW_XSHADOW = IXShadow(_new_xshadow);
    }

    /// @notice Migrate tokens from old to new version
    /// @dev Transfers tokens from user to this contract and sends new tokens back
    /// @param _amount Amount of tokens to migrate
    /// @param _xShadow Boolean flag - true for xSHADOW migration, false for SHADOW migration
    function shift(uint256 _amount, bool _xShadow) external whileNotPaused {
        MigrationState memory state = userMigrationData[msg.sender];
        if (_xShadow) {
            XSHADOW.transferFrom(msg.sender, address(this), _amount);
            state.amountXShadow += _amount;
            NEW_XSHADOW.transfer(msg.sender, _amount);
            emit Changed(address(XSHADOW), msg.sender, _amount);
        } else {
            SHADOW.transferFrom(msg.sender, address(this), _amount);
            state.amountShadow += _amount;
            NEW_SHADOW.transfer(msg.sender, _amount);
            emit Changed(address(SHADOW), msg.sender, _amount);
        }
        userMigrationData[msg.sender] = state;
        _collect();
    }

    function _collect() internal {
        uint256 balance = SHADOW.balanceOf(address(this));
        uint256 xBalance = XSHADOW.balanceOf(address(this));
        if (balance > 0) {
            SHADOW.transfer(reservoir, balance);
            emit Collected(reservoir, address(SHADOW), balance);
        }
        if (xBalance > 0) {
            XSHADOW.transfer(reservoir, xBalance);
            emit Collected(reservoir, address(XSHADOW), xBalance);
        }
    }
}
