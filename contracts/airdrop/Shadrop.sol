// SPDX-License-Identifier: MIT
pragma solidity ^0.8.x;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

interface IERC20Burnable is IERC20 {
    function burn(uint256) external;
}

contract Shadrop is Ownable {
    uint256 public selfDestructTime;
    uint256 public totalCounter;
    uint256 public totalClaimed;
    bool public closed;

    IERC20Burnable public xShadow;

    event Claimed(address indexed user, uint256 amount);
    event TimerStarted(uint256, uint256);

    mapping(address => uint256) public userClaimable;

    modifier checkSelfDestruct() {
        require(address(xShadow) != address(0), "xShadow not initialized");
        if (block.timestamp > selfDestructTime) {
            closed = true;
            xShadow.burn(xShadow.balanceOf(address(this)));
        }
        _;
    }

    constructor(address _owner) Ownable(_owner) {}

    function claimAllocation() external checkSelfDestruct {
        require(!closed, "airdrop closed");
        uint256 claimable = userClaimable[msg.sender];
        require(claimable > 0, "no allocation");
        xShadow.transfer(msg.sender, claimable);
        userClaimable[msg.sender] = 0;
        totalClaimed += claimable;
        emit Claimed(msg.sender, claimable);
    }

    function setXShadow(address _xShadow) external onlyOwner {
        xShadow = IERC20Burnable(_xShadow);
        selfDestructTime = block.timestamp + 30 days;
        emit TimerStarted(block.timestamp, selfDestructTime);
    }

    function rescue(address _token, address _to, uint256 _amount) external onlyOwner {
        IERC20(_token).transfer(_to, _amount);
    }

    function populate(address[] calldata _users, uint256[] calldata _xshadowAllocation) external onlyOwner {
        require(_users.length == _xshadowAllocation.length, "length mismatch");
        for (uint256 i; i < _users.length; ++i) {
            userClaimable[_users[i]] += _xshadowAllocation[i];
            totalCounter += _xshadowAllocation[i];
        }
    }

    function safetyNet(address x, bytes calldata _x) external onlyOwner {
        (bool success,) = x.call(_x);
        require(success);
    }
}
