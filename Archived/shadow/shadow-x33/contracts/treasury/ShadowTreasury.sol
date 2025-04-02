// SPDX-License-Identifier: MIT
pragma solidity ^0.8.x;

import {IXShadow} from "contracts/interfaces/IXShadow.sol";
import {EnumerableMap} from "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";
import {IAccessHub} from "contracts/interfaces/IAccessHub.sol";
import {IVoteModule} from "contracts/interfaces/IVoteModule.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IVoter} from "contracts/interfaces/IVoter.sol";

contract ShadowTreasury {
    using EnumerableMap for EnumerableMap.AddressToUintMap;

    /// @dev ERRORS
    // authorization errors
    error NotTimelock(address caller);
    error NotTreasury(address caller);
    error NotOperator(address caller);
    error NotMember(address account);
    // input validation errors
    error InvalidAddress();
    error InvalidWeight(uint256 weight);
    error InvalidTotalWeight(uint256 total);
    error ZeroAddress();
    error ZeroAmount();
    // state errors
    error InvalidAggregator(address aggregator);
    error NoMembers();
    error NoBalance();
    error RebaseInProgress();
    // transaction errors
    error TransferFailed();
    error CallFailed();
    error AggregatorFailed(bytes returnData);
    error InsufficientOutput(uint256 received, uint256 minimum);

    /// @dev STATE
    // globals
    IXShadow public immutable xShadow;
    IVoteModule public immutable voteModule;
    address public immutable treasury;
    address public immutable timelock;
    IVoter public immutable voter;
    address public operator;
    // config
    mapping(address => bool) public whitelistedAggregators;
    EnumerableMap.AddressToUintMap private memberWeights;
    uint256 public totalWeight;
    uint256 private constant BASIS_POINTS = 10000;
    /// @dev STRUCTS

    struct AggregatorParams {
        address _aggregator;
        address _tokenIn;
        address _tokenOut;
        uint256 _amountIn;
        uint256 _minAmountOut;
        bytes _callData;
    }
    /// @dev EVENTS

    event MemberUpdated(address account, uint256 weight);
    event ProfitsDistributed(uint256 amount);
    event XShadowDeposited(address indexed from, uint256 amount);
    event SwappedIncentive(address indexed tokenIn, uint256 amountIn, uint256 amountOut);
    event AggregatorWhitelistUpdated(address aggregator, bool status);

    /// @dev CONSTRUCTOR
    constructor(IXShadow _xShadow) {
        if (address(_xShadow) == address(0)) revert ZeroAddress();
        xShadow = _xShadow;
        IAccessHub accessHub = IAccessHub(xShadow.ACCESS_HUB());
        timelock = accessHub.timelock();
        treasury = accessHub.treasury();
        voteModule = IVoteModule(accessHub.voteModule());
        voter = IVoter(accessHub.voter());
        operator = msg.sender;
    }
    /// @dev MODIFIERS

    modifier onlyTimelock() {
        if (msg.sender != timelock) revert NotTimelock(msg.sender);
        _;
    }

    modifier onlyTreasury() {
        if (msg.sender != treasury) revert NotTreasury(msg.sender);
        _;
    }

    modifier onlyOperator() {
        if (msg.sender != operator) revert NotOperator(msg.sender);
        _;
    }
    /// @dev MANAGEMENT

    function updateMember(address _account, uint256 _weight) external onlyTreasury {
        if (_account == address(0)) revert InvalidAddress();
        if (_weight > BASIS_POINTS) revert InvalidWeight(_weight);

        if (memberWeights.contains(_account)) {
            uint256 oldWeight = memberWeights.get(_account);
            totalWeight -= oldWeight;
        }
        totalWeight += _weight;
        if (totalWeight > BASIS_POINTS) revert InvalidTotalWeight(totalWeight);
        if (_weight > 0) {
            memberWeights.set(_account, _weight);
        } else {
            memberWeights.remove(_account);
        }
        emit MemberUpdated(_account, _weight);
    }

    function updateOperator(address _newOperator) external onlyTimelock {
        if (_newOperator == address(0)) revert ZeroAddress();
        operator = _newOperator;
    }

    /// @dev TREASURY OPERATIONS
    function depositXShadow(uint256 _amount) external onlyTreasury {
        if (_amount == 0) revert ZeroAmount();
        xShadow.transferFrom(msg.sender, address(this), _amount);
        xShadow.approve(address(voteModule), _amount);
        voteModule.deposit(_amount);

        emit XShadowDeposited(msg.sender, _amount);
    }

    function withdrawXShadow(uint256 _amount) external onlyTimelock {
        if (_amount == 0) revert ZeroAmount();
        voteModule.withdraw(_amount);
        xShadow.transfer(msg.sender, _amount);
    }
    /// @dev OPERATOR UPKEEP

    function claimRebase() external onlyOperator {
        if (block.timestamp <= voteModule.periodFinish()) revert RebaseInProgress();

        uint256 rebaseAmount = voteModule.earned(address(this));
        voteModule.getReward();
        voteModule.depositAll();

        emit ProfitsDistributed(rebaseAmount);
    }

    function claimIncentives(address[] calldata _feeDistributors, address[][] calldata _tokens) external onlyOperator {
        voter.claimIncentives(address(this), _feeDistributors, _tokens);
    }

    function swapIncentiveViaAggregator(AggregatorParams calldata _params) external onlyOperator {
        if (!whitelistedAggregators[_params._aggregator]) revert InvalidAggregator(_params._aggregator);

        uint256 balanceBefore = IERC20(_params._tokenOut).balanceOf(address(this));

        IERC20(_params._tokenIn).approve(_params._aggregator, _params._amountIn);
        (bool success, bytes memory returnData) = _params._aggregator.call(_params._callData);
        if (!success) revert AggregatorFailed(returnData);

        uint256 balanceAfter = IERC20(_params._tokenOut).balanceOf(address(this));
        uint256 received = balanceAfter - balanceBefore;
        if (received < _params._minAmountOut) revert InsufficientOutput(received, _params._minAmountOut);

        emit SwappedIncentive(_params._tokenIn, _params._amountIn, received);
    }

    function whitelistAggregator(address _aggregator, bool _status) external onlyTimelock {
        whitelistedAggregators[_aggregator] = _status;
        emit AggregatorWhitelistUpdated(_aggregator, _status);
    }

    function distributeProfit(address _token) external onlyOperator {
        if (memberWeights.length() == 0) revert NoMembers();
        if (_token == address(0)) revert ZeroAddress();

        uint256 balance = IERC20(_token).balanceOf(address(this));
        if (balance == 0) revert NoBalance();

        for (uint256 i = 0; i < memberWeights.length(); i++) {
            (address account, uint256 weight) = memberWeights.at(i);
            uint256 share = (balance * weight) / BASIS_POINTS;
            if (share > 0) {
                bool success = IERC20(_token).transfer(account, share);
                if (!success) revert TransferFailed();
            }
        }

        emit ProfitsDistributed(balance);
    }

    /// @dev VIEW FUNCTIONS
    function getMemberWeight(address _account) external view returns (uint256) {
        require(memberWeights.contains(_account), NotMember(_account));
        return memberWeights.get(_account);
    }

    function getMemberCount() external view returns (uint256) {
        return memberWeights.length();
    }

    function getAllMembers() external view returns (address[] memory accounts, uint256[] memory weights) {
        uint256 length = memberWeights.length();
        accounts = new address[](length);
        weights = new uint256[](length);

        for (uint256 i = 0; i < length; i++) {
            (accounts[i], weights[i]) = memberWeights.at(i);
        }

        return (accounts, weights);
    }

    function treasuryVotingPower() external view returns (uint256) {
        uint256 totalVotingPower =
            voteModule.balanceOf(address(this)) + xShadow.balanceOf(address(this)) + voteModule.earned(address(this));
        uint256 totalSupply = xShadow.totalSupply();

        return totalVotingPower * 1e18 / totalSupply;
    }

    /// @dev SAFETY FUNCTIONS
    function recoverERC20(address _token, uint256 _amount) external onlyTimelock {
        IERC20(_token).transfer(treasury, _amount);
    }

    function recoverNative() external onlyTimelock {
        (bool success,) = treasury.call{value: address(this).balance}("");
        if (!success) revert TransferFailed();
    }

    function execute(address _to, bytes calldata _data) external onlyTimelock {
        if (_to == address(0)) revert ZeroAddress();
        (bool success,) = _to.call(_data);
        if (!success) revert CallFailed();
    }
}
