// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.x;

import {IShadowV3Factory} from "./interfaces/IShadowV3Factory.sol";
import {IShadowV3PoolDeployer} from "./interfaces/IShadowV3PoolDeployer.sol";
import {IShadowV3Pool} from "./interfaces/IShadowV3Pool.sol";
import {Errors} from "contracts/libraries/Errors.sol";

/// @title Canonical Shadow V3 factory
/// @notice Deploys Shadow V3 pools and manages ownership and control over pool protocol fees
contract ShadowV3Factory is IShadowV3Factory {
    address public shadowV3PoolDeployer;
    /// @inheritdoc IShadowV3Factory
    uint8 public override feeProtocol;

    /// @inheritdoc IShadowV3Factory
    address public feeCollector;
    address public accessHub;
    address public voter;

    struct Parameters {
        address factory;
        address token0;
        address token1;
        uint24 fee;
        int24 tickSpacing;
    }

    /// @inheritdoc IShadowV3Factory
    Parameters public parameters;

    /// @inheritdoc IShadowV3Factory
    mapping(int24 tickSpacing => uint24 initialFee) public override tickSpacingInitialFee;
    /// @inheritdoc IShadowV3Factory
    mapping(address tokenA => mapping(address tokenB => mapping(int24 tickSpacing => address pool))) public override
        getPool;
    /// @dev mapping that tells us whether the pair is a CL (v3) pair or not
    mapping(address pool => bool isV3) public isPairV3;
    /// @dev pool specific fee protocol if set
    mapping(address pool => uint8 feeProtocol) _poolFeeProtocol;

    modifier onlyGovernance() {
        require(msg.sender == accessHub, "!GOV");
        _;
    }

    /// @dev set initial tickspacings and feeSplits
    constructor(address _accessHub) {
        accessHub = _accessHub;
        /// @dev 0.01% fee, 1bps tickspacing
        tickSpacingInitialFee[1] = 100;
        emit TickSpacingEnabled(1, 100);
        /// @dev 0.025% fee, 5bps tickspacing
        tickSpacingInitialFee[5] = 250;
        emit TickSpacingEnabled(5, 250);
        /// @dev 0.05% fee, 10bps tickspacing
        tickSpacingInitialFee[10] = 500;
        emit TickSpacingEnabled(10, 500);
        /// @dev 0.30% fee, 50bps tickspacing
        tickSpacingInitialFee[50] = 3000;
        emit TickSpacingEnabled(50, 3000);
        /// @dev 1.00% fee, 100 bps tickspacing
        tickSpacingInitialFee[100] = 10000;
        emit TickSpacingEnabled(100, 10000);
        /// @dev 2.00% fee, 200 bps tickspacing
        tickSpacingInitialFee[200] = 20000;
        emit TickSpacingEnabled(200, 20000);

        /// @dev the initial feeSplit of what is sent to the FeeCollector to be distributed to voters
        /// @dev 5% to FeeCollector
        feeProtocol = 5;

        shadowV3PoolDeployer = msg.sender;

        emit SetFeeProtocol(0, feeProtocol);
    }

    function initialize(address _shadowV3PoolDeployer) external {
        require(shadowV3PoolDeployer == msg.sender);
        shadowV3PoolDeployer = _shadowV3PoolDeployer;
    }

    /// @inheritdoc IShadowV3Factory
    function createPool(address tokenA, address tokenB, int24 tickSpacing, uint160 sqrtPriceX96)
        external
        override
        returns (address pool)
    {
        /// @dev ensure the tokens aren't identical
        require(tokenA != tokenB, Errors.IDENTICAL_TOKENS());
        /// @dev sort the tokens
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        /// @dev check that token0 doesn't equal the zero address
        require(token0 != address(0), Errors.ADDRESS_ZERO());
        /// @dev fetch the fee from the initial tickspacing mapping
        uint24 fee = tickSpacingInitialFee[tickSpacing];
        /// @dev ensure the fee is not 0
        require(fee != 0, Errors.F0());
        /// @dev ensure the pool doesn't exist already
        require(getPool[token0][token1][tickSpacing] == address(0), Errors.PAIR_EXISTS());
        parameters =
            Parameters({factory: address(this), token0: token0, token1: token1, fee: fee, tickSpacing: tickSpacing});
        pool = IShadowV3PoolDeployer(shadowV3PoolDeployer).deploy(token0, token1, tickSpacing);
        delete parameters;

        getPool[token0][token1][tickSpacing] = pool;
        /// @dev populate mapping in the reverse direction, deliberate choice to avoid the cost of comparing addresses
        getPool[token1][token0][tickSpacing] = pool;
        /// @dev update mapping
        isPairV3[pool] = true;
        emit PoolCreated(token0, token1, fee, tickSpacing, pool);

        /// @dev if there is a sqrtPrice, initialize it to the pool
        if (sqrtPriceX96 > 0) {
            IShadowV3Pool(pool).initialize(sqrtPriceX96);
        }
    }

    /// @inheritdoc IShadowV3Factory
    function enableTickSpacing(int24 tickSpacing, uint24 initialFee) external override onlyGovernance {
        require(initialFee < 1_000_000, Errors.FEE_TOO_LARGE());
        /// @dev tick spacing is capped at 16384 to prevent the situation where tickSpacing is so large that
        /// @dev TickBitmap#nextInitializedTickWithinOneWord overflows int24 container from a valid tick
        /// @dev 16384 ticks represents a >5x price change with ticks of 1 bips
        require(tickSpacing > 0 && tickSpacing < 16384, "TS");
        require(tickSpacingInitialFee[tickSpacing] == 0, "TS!0");

        tickSpacingInitialFee[tickSpacing] = initialFee;
        emit TickSpacingEnabled(tickSpacing, initialFee);
    }

    /// @inheritdoc IShadowV3Factory
    function setFeeProtocol(uint8 _feeProtocol) external override onlyGovernance {
        require(_feeProtocol <= 100, Errors.FEE_TOO_LARGE());
        uint8 feeProtocolOld = feeProtocol;
        feeProtocol = _feeProtocol;
        emit SetFeeProtocol(feeProtocolOld, _feeProtocol);
    }

    /// @inheritdoc IShadowV3Factory
    function setPoolFeeProtocol(address pool, uint8 _feeProtocol) external onlyGovernance {
        require(_feeProtocol <= 100, Errors.FEE_TOO_LARGE());
        uint8 feeProtocolOld = poolFeeProtocol(pool);
        _poolFeeProtocol[pool] = _feeProtocol;
        emit SetPoolFeeProtocol(pool, feeProtocolOld, _feeProtocol);

        IShadowV3Pool(pool).setFeeProtocol();
    }

    /// @inheritdoc IShadowV3Factory
    function gaugeFeeSplitEnable(address pool) external {
        if (msg.sender != voter) {
            IShadowV3Pool(pool).setFeeProtocol();
        } else {
            _poolFeeProtocol[pool] = 100;
            IShadowV3Pool(pool).setFeeProtocol();
        }
    }

    /// @inheritdoc IShadowV3Factory
    function poolFeeProtocol(address pool) public view override returns (uint8 __poolFeeProtocol) {
        /// @dev override to make 5 default if unstated (gaugeless mode)
        return (_poolFeeProtocol[pool] == 0 ? 5 : _poolFeeProtocol[pool]);
    }

    /// @inheritdoc IShadowV3Factory
    function setFeeCollector(address _feeCollector) external override onlyGovernance {
        emit FeeCollectorChanged(feeCollector, _feeCollector);
        feeCollector = _feeCollector;
    }

    /// @inheritdoc IShadowV3Factory
    function setVoter(address _voter) external onlyGovernance {
        voter = _voter;
    }

    /// @inheritdoc IShadowV3Factory
    function setFee(address _pool, uint24 _fee) external override onlyGovernance {
        IShadowV3Pool(_pool).setFee(_fee);

        emit FeeAdjustment(_pool, _fee);
    }
}
