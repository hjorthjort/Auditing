// SPDX-License-Identifier: MIT
pragma solidity ^0.8.x;

import {IVoter} from "../interfaces/IVoter.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

interface IMockGauge {
    function notifyRewardAmount(address token, uint256 amount) external;
}

contract ActingNotifier {
    address private operator;

    IVoter private VOTER;

    IERC20 private xShadow;

    modifier onlyOperator() {
        require(msg.sender == operator, "!operator");
        _;
    }

    constructor(address _voter, address _xShadow) {
        operator = msg.sender;
        VOTER = IVoter(_voter);
        xShadow = IERC20(_xShadow);
    }

    function notifyEmissions(address[] calldata pools, uint256[] calldata emissions) external onlyOperator {
        for (uint256 i; i < pools.length; ++i) {
            address pool = pools[i];
            address gauge = VOTER.gaugeForPool(pool);
            uint256 amount = emissions[i];
            xShadow.approve(gauge, amount);
            IMockGauge(gauge).notifyRewardAmount(address(xShadow), amount);
        }
    }

    function rescue(address token) external onlyOperator {
        IERC20(token).transfer(operator, IERC20(token).balanceOf(address(this)));
    }

    function setNewOperator(address _newOperator) external onlyOperator {
        operator = _newOperator;
    }
}
