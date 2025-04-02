// SPDX-License-Identifier: MIT
pragma solidity ^0.8.x;

import {IVoter} from "../interfaces/IVoter.sol";
import {IFeeCollector} from "../CL/gauge/interfaces/IFeeCollector.sol";
import {IShadowV3Pool} from "../CL/core/interfaces/IShadowV3Pool.sol";

interface IModifiedVoter is IVoter {
    function isClGauge(address) external view returns (bool);
}

interface IMockGauge {
    function pool() external view returns (address);
    function stake() external view returns (address);
}

interface IMockPool {
    function mintFee() external;
    function feeRecipient() external view returns (address);
}

interface IMockFeeRecipient {
    function notifyFees() external;
}

interface IMockFactory {
    function isPairV3(address) external view returns (bool);
    function isPair(address) external view returns (bool);
}

/// @title Automated Fee Notifier
/// @notice Automates protocol fee collection for Shadow CL pools
/// @dev Works in conjunction with FeeCollector contract to batch process fees
contract AutomatedFeeNotifier {
    IModifiedVoter private immutable VOTER;
    IFeeCollector private immutable COLLECTOR;
    IMockFactory private immutable LEGACY_FACTORY;
    IMockFactory private immutable V3_FACTORY;

    /// @notice Initializes the contract with Voter and FeeCollector addresses
    /// @param _voter Address of the Voter contract
    /// @param _collector Address of the FeeCollector contract
    constructor(address _voter, address _collector, address _legacyFactory, address _v3Factory) {
        VOTER = IModifiedVoter(_voter);
        COLLECTOR = IFeeCollector(_collector);
        LEGACY_FACTORY = IMockFactory(_legacyFactory);
        V3_FACTORY = IMockFactory(_v3Factory);
    }

    /// @notice Processes protocol fees for specified pools
    /// @param _pools Array of pool addresses to collect fees from
    function notify(IShadowV3Pool[] calldata _pools) external {
        for (uint256 i; i < _pools.length; ++i) {
            uint8 v = _version(address(_pools[i]));
            IMockPool mp = IMockPool(address(_pools[i]));
            if (v == 0) revert("v = 0");
            if (v == 3) {
                COLLECTOR.collectProtocolFees(_pools[i]);
            } else {
                mp.mintFee();
                IMockFeeRecipient(mp.feeRecipient()).notifyFees();
            }
        }
    }

    /// @notice Processes fees for a range of eligible pools
    /// @param _index Starting index in the eligible pairs array
    /// @param _end Ending index (exclusive) in the eligible pairs array
    /// @dev Will adjust _end if it exceeds array bounds
    function blindPush(uint256 _index, uint256 _end) external {
        address[] memory targets = eligiblePairs();
        _end = _end > targets.length ? targets.length : _end;
        require(_index <= targets.length, "Index out of bounds");

        for (; _index < _end; ++_index) {
            COLLECTOR.collectProtocolFees(IShadowV3Pool(targets[_index]));
        }
    }

    /// @notice Returns pending protocol fees for a specific pool
    /// @param _pool Address of the pool to check
    /// @return _poolID Address of the pool checked
    /// @return _tokens Array of token addresses [token0, token1]
    /// @return _amounts Array of pending fee amounts [amount0, amount1]
    function pendingFees(address _pool)
        external
        view
        returns (address _poolID, address[] memory _tokens, uint128[] memory _amounts)
    {
        _tokens = new address[](2);
        _amounts = new uint128[](2);

        _tokens[0] = IShadowV3Pool(_pool).token0();
        _tokens[1] = IShadowV3Pool(_pool).token1();
        (_amounts[0], _amounts[1]) = IShadowV3Pool(_pool).protocolFees();

        return (_pool, _tokens, _amounts);
    }

    /// @notice Returns array of all eligible pool addresses
    /// @dev Filters all gauges to return only pool addresses from all gauges
    /// @return _pairs Array of eligible pool addresses
    function eligiblePairs() public view returns (address[] memory _pairs) {
        address[] memory allGauges = VOTER.getAllGauges();
        _pairs = new address[](allGauges.length);

        for (uint256 i; i < allGauges.length; ++i) {
            IMockGauge mg = IMockGauge(allGauges[i]);
            if (VOTER.isClGauge(address(mg))) {
                _pairs[i] = mg.pool();
            } else {
                _pairs[i] = mg.stake();
            }
        }
        return _pairs;
    }

    function _version(address pool) internal view returns (uint8 version) {
        /// @dev there are more CL pools with high fees than legacy, so we put it first for gas efficiency
        if (V3_FACTORY.isPairV3(pool)) return 3;
        if (LEGACY_FACTORY.isPair(pool)) return 2;
        return 0;
    }
}
