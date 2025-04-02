// SPDX-License-Identifier: MIT
pragma solidity ^0.8.x;

import {IAccessHub} from "./interfaces/IAccessHub.sol";
import {Errors} from "contracts/libraries/Errors.sol";
import {
    AccessControlEnumerableUpgradeable,
    Initializable
} from "@openzeppelin-contracts-upgradeable/access/extensions/AccessControlEnumerableUpgradeable.sol";

import {ILauncherPlugin} from "./interfaces/ILauncherPlugin.sol";
import {IXShadow} from "./interfaces/IXShadow.sol";
import {IX33} from "./interfaces/IX33.sol";

import {IShadowV3Factory} from "./CL/core/interfaces/IShadowV3Factory.sol";
import {IShadowV3Pool} from "./CL/core/interfaces/IShadowV3Pool.sol";
import {IGaugeV3} from "./CL/gauge/interfaces/IGaugeV3.sol";
import {IFeeCollector} from "./CL/gauge/interfaces/IFeeCollector.sol";
import {INonfungiblePositionManager} from "./CL/periphery/interfaces/INonfungiblePositionManager.sol";
import {IFeeDistributor} from "./interfaces/IFeeDistributor.sol";

import {IPairFactory} from "./interfaces/IPairFactory.sol";
import {IFeeRecipientFactory} from "./interfaces/IFeeRecipientFactory.sol";

import {IVoter} from "./interfaces/IVoter.sol";
import {IMinter} from "./interfaces/IMinter.sol";
import {IVoteModule} from "./interfaces/IVoteModule.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";

contract AccessHub is IAccessHub, Initializable, AccessControlEnumerableUpgradeable {
    /**
     * Start of Storage Slots
     */

    /// @notice role that can call changing fee splits and swap fees
    bytes32 public constant SWAP_FEE_SETTER = keccak256("SWAP_FEE_SETTER");
    /// @notice operator role
    bytes32 public constant PROTOCOL_OPERATOR = keccak256("PROTOCOL_OPERATOR");

    /// @inheritdoc IAccessHub
    address public timelock;
    /// @inheritdoc IAccessHub
    address public treasury;

    /**
     * "nice-to-have" addresses for quickly finding contracts within the system
     */

    /// @inheritdoc IAccessHub
    address public clGaugeFactory;
    /// @inheritdoc IAccessHub
    address public gaugeFactory;
    /// @inheritdoc IAccessHub
    address public feeDistributorFactory;

    /**
     * core contracts
     */

    /// @notice central voter contract
    IVoter public voter;
    /// @notice weekly emissions minter
    IMinter public minter;
    /// @notice launchpad plugin for augmenting feeshare
    ILauncherPlugin public launcherPlugin;
    /// @notice xShadow contract
    IXShadow public xShadow;
    /// @notice X33 contract
    IX33 public x33;
    /// @notice CL V3 factory
    IShadowV3Factory public shadowV3PoolFactory;
    /// @notice legacy pair factory
    IPairFactory public poolFactory;
    /// @notice legacy fees holder contract
    IFeeRecipientFactory public feeRecipientFactory;
    /// @notice fee collector contract
    IFeeCollector public feeCollector;
    /// @notice voteModule contract
    IVoteModule public voteModule;
    /// @notice NFPManager contract
    INonfungiblePositionManager public nfpManager;

    /**
     * End of Storage Slots
     */
    modifier timelocked() {
        require(msg.sender == timelock, Errors.NOT_TIMELOCK(msg.sender));
        _;
    }

    constructor() {
        _disableInitializers();
    }

    /// @inheritdoc IAccessHub
    function initialize(InitParams calldata params) external initializer {
        /// @dev initialize all external interfaces
        timelock = params.timelock;
        treasury = params.treasury;
        voter = IVoter(params.voter);
        minter = IMinter(params.minter);
        launcherPlugin = ILauncherPlugin(params.launcherPlugin);
        xShadow = IXShadow(params.xShadow);
        x33 = IX33(params.x33);
        shadowV3PoolFactory = IShadowV3Factory(params.shadowV3PoolFactory);
        poolFactory = IPairFactory(params.poolFactory);
        feeRecipientFactory = IFeeRecipientFactory(params.feeRecipientFactory);
        feeCollector = IFeeCollector(params.feeCollector);
        voteModule = IVoteModule(params.voteModule);

        /// @dev reference addresses
        clGaugeFactory = params.clGaugeFactory;
        gaugeFactory = params.gaugeFactory;
        feeDistributorFactory = params.feeDistributorFactory;

        /// @dev fee setter role given to treasury
        _grantRole(SWAP_FEE_SETTER, params.treasury);
        /// @dev operator role given to treasury
        _grantRole(PROTOCOL_OPERATOR, params.treasury);
        /// @dev initially give admin role to treasury
        _grantRole(DEFAULT_ADMIN_ROLE, params.treasury);
        /// @dev give timelock the admin role
        _grantRole(DEFAULT_ADMIN_ROLE, params.timelock);
    }

    function reinit(InitParams calldata params) external timelocked {
        voter = IVoter(params.voter);
        minter = IMinter(params.minter);
        launcherPlugin = ILauncherPlugin(params.launcherPlugin);
        xShadow = IXShadow(params.xShadow);
        x33 = IX33(params.x33);
        shadowV3PoolFactory = IShadowV3Factory(params.shadowV3PoolFactory);
        poolFactory = IPairFactory(params.poolFactory);
        feeRecipientFactory = IFeeRecipientFactory(params.feeRecipientFactory);
        feeCollector = IFeeCollector(params.feeCollector);
        voteModule = IVoteModule(params.voteModule);

        /// @dev reference addresses
        clGaugeFactory = params.clGaugeFactory;
        gaugeFactory = params.gaugeFactory;
        feeDistributorFactory = params.feeDistributorFactory;
    }

    /// @inheritdoc IAccessHub
    function initializeVoter(
        address _shadow,
        address _legacyFactory,
        address _gauges,
        address _feeDistributorFactory,
        address _minter,
        address _msig,
        address _xShadow,
        address _clFactory,
        address _clGaugeFactory,
        address _nfpManager,
        address _feeRecipientFactory,
        address _voteModule,
        address _launcherPlugin
    ) external timelocked {
        voter.initialize(
            _shadow,
            _legacyFactory,
            _gauges,
            _feeDistributorFactory,
            _minter,
            _msig,
            _xShadow,
            _clFactory,
            _clGaugeFactory,
            _nfpManager,
            _feeRecipientFactory,
            _voteModule,
            _launcherPlugin
        );
    }

    /**
     * Fee Setting Logic
     */

    /// @inheritdoc IAccessHub
    function setSwapFees(address[] calldata _pools, uint24[] calldata _swapFees, bool[] calldata _concentrated)
        external
        onlyRole(SWAP_FEE_SETTER)
    {
        /// @dev ensure continuity of length
        require(_pools.length == _swapFees.length && _swapFees.length == _concentrated.length, Errors.LENGTH_MISMATCH());
        for (uint256 i; i < _pools.length; ++i) {
            /// @dev we check if the pool is v3 or legacy and set their fees accordingly
            if (_concentrated[i]) {
                shadowV3PoolFactory.setFee(_pools[i], _swapFees[i]);
            } else {
                poolFactory.setPairFee(_pools[i], _swapFees[i]);
            }
        }
    }

    /// @inheritdoc IAccessHub
    function setFeeSplitCL(address[] calldata _pools, uint8[] calldata _feeProtocol)
        external
        onlyRole(SWAP_FEE_SETTER)
    {
        /// @dev ensure continuity of length
        require(_pools.length == _feeProtocol.length, Errors.LENGTH_MISMATCH());
        for (uint256 i; i < _pools.length; ++i) {
            shadowV3PoolFactory.setPoolFeeProtocol(_pools[i], _feeProtocol[i]);
        }
    }

    /// @inheritdoc IAccessHub
    function setFeeSplitLegacy(address[] calldata _pools, uint256[] calldata _feeSplits)
        external
        onlyRole(SWAP_FEE_SETTER)
    {
        /// @dev ensure continuity of length
        require(_pools.length == _feeSplits.length, Errors.LENGTH_MISMATCH());
        for (uint256 i; i < _pools.length; ++i) {
            poolFactory.setPairFeeSplit(_pools[i], _feeSplits[i]);
        }
    }

    /**
     * Voter governance
     */

    /// @inheritdoc IAccessHub
    function setNewGovernorInVoter(address _newGovernor) external onlyRole(PROTOCOL_OPERATOR) {
        /// @dev no checks are needed as the voter handles this already
        voter.setGovernor(_newGovernor);
    }

    /// @inheritdoc IAccessHub
    function governanceWhitelist(address[] calldata _token, bool[] calldata _whitelisted)
        external
        onlyRole(PROTOCOL_OPERATOR)
    {
        /// @dev ensure continuity of length
        require(_token.length == _whitelisted.length, Errors.LENGTH_MISMATCH());
        for (uint256 i; i < _token.length; ++i) {
            /// @dev if adding to the whitelist
            if (_whitelisted[i]) {
                /// @dev call the voter's whitelist function
                voter.whitelist(_token[i]);
            }
            /// @dev remove the token's whitelist
            else {
                voter.revokeWhitelist(_token[i]);
            }
        }
    }

    /// @inheritdoc IAccessHub
    function killGauge(address[] calldata _pairs) external onlyRole(PROTOCOL_OPERATOR) {
        for (uint256 i; i < _pairs.length; ++i) {
            /// @dev store pair
            address pair = _pairs[i];
            if (poolFactory.isPair(pair)) {
                voter.killGauge(voter.gaugeForPool(pair));
            } else {
                /// @dev collect fees from the pair
                feeCollector.collectProtocolFees(IShadowV3Pool(pair));
                /// @dev kill the gauge
                voter.killGauge(voter.gaugeForPool(pair));
                /// @dev set the new fees in the pair to 95/5
                shadowV3PoolFactory.setPoolFeeProtocol(pair, 5);
            }
        }
    }

    /// @inheritdoc IAccessHub
    function reviveGauge(address[] calldata _pairs) external onlyRole(PROTOCOL_OPERATOR) {
        for (uint256 i; i < _pairs.length; ++i) {
            address pair = _pairs[i];
            if (poolFactory.isPair(pair)) {
                voter.reviveGauge(voter.gaugeForPool(pair));
            } else {
                /// @dev collect fees from the pair
                feeCollector.collectProtocolFees(IShadowV3Pool(pair));
                /// @dev revive the pair
                voter.reviveGauge(voter.gaugeForPool(pair));
                /// @dev set fee to the factory default
                shadowV3PoolFactory.setPoolFeeProtocol(pair, shadowV3PoolFactory.feeProtocol());
            }
        }
    }

    /// @inheritdoc IAccessHub
    function setEmissionsRatioInVoter(uint256 _pct) external onlyRole(PROTOCOL_OPERATOR) {
        voter.setGlobalRatio(_pct);
    }

    /// @inheritdoc IAccessHub
    function retrieveStuckEmissionsToGovernance(address _gauge, uint256 _period) external onlyRole(PROTOCOL_OPERATOR) {
        voter.stuckEmissionsRecovery(_gauge, _period);
    }

    /// @inheritdoc IAccessHub
    function setMainTickSpacingInVoter(address tokenA, address tokenB, int24 tickSpacing)
        external
        onlyRole(PROTOCOL_OPERATOR)
    {
        voter.setMainTickSpacing(tokenA, tokenB, tickSpacing);
    }

    function createGaugeForPool(address _pool) external onlyRole(PROTOCOL_OPERATOR) {
        bool isCl = shadowV3PoolFactory.isPairV3(_pool);
        if (isCl) {
            IShadowV3Pool poolv3 = IShadowV3Pool(_pool);
            (address token0, address token1, int24 tickSpacing) =
                (poolv3.token0(), poolv3.token1(), poolv3.tickSpacing());
            voter.createCLGauge(token0, token1, tickSpacing);
        } else {
            voter.createGauge(_pool);
        }
    }

    /// @inheritdoc IAccessHub
    function resetVotesOnBehalfOf(address _user) external timelocked {
        voter.reset(_user);
    }

    /**
     * xShadow Functions
     */

    /// @inheritdoc IAccessHub
    function transferWhitelistInXShadow(address[] calldata _who, bool[] calldata _whitelisted)
        external
        onlyRole(PROTOCOL_OPERATOR)
    {
        /// @dev ensure continuity of length
        require(_who.length == _whitelisted.length, Errors.LENGTH_MISMATCH());
        xShadow.setExemption(_who, _whitelisted);
    }

    /// @inheritdoc IAccessHub
    function transferToWhitelistInXShadow(address[] calldata _who, bool[] calldata _whitelisted)
        external
        onlyRole(PROTOCOL_OPERATOR)
    {
        /// @dev ensure continuity of length
        require(_who.length == _whitelisted.length, Errors.LENGTH_MISMATCH());
        xShadow.setExemptionTo(_who, _whitelisted);
    }

    /// @inheritdoc IAccessHub
    function toggleXShadowGovernance(bool enable) external onlyRole(PROTOCOL_OPERATOR) {
        /// @dev if enabled we call unpause otherwise we pause to disable
        enable ? xShadow.unpause() : xShadow.pause();
    }

    /// @inheritdoc IAccessHub
    function operatorRedeemXShadow(uint256 _amount) external onlyRole(PROTOCOL_OPERATOR) {
        xShadow.operatorRedeem(_amount);
    }

    /// @inheritdoc IAccessHub
    function migrateOperator(address _operator) external onlyRole(PROTOCOL_OPERATOR) {
        xShadow.migrateOperator(_operator);
    }

    /// @inheritdoc IAccessHub
    function rescueTrappedTokens(address[] calldata _tokens, uint256[] calldata _amounts)
        external
        onlyRole(PROTOCOL_OPERATOR)
    {
        xShadow.rescueTrappedTokens(_tokens, _amounts);
    }

    /**
     * X33 Functions
     */

    /// @inheritdoc IAccessHub
    function transferOperatorInX33(address _newOperator) external onlyRole(PROTOCOL_OPERATOR) {
        x33.transferOperator(_newOperator);
    }

    /**
     * Minter Functions
     */

    /// @inheritdoc IAccessHub
    function setEmissionsMultiplierInMinter(uint256 _multiplier) external onlyRole(PROTOCOL_OPERATOR) {
        minter.updateEmissionsMultiplier(_multiplier);
    }

    /**
     * Reward List Functions
     */
    /// @inheritdoc IAccessHub
    function removeFeeDistributorRewards(address[] calldata _pools, address[] calldata _rewards)
        external
        onlyRole(PROTOCOL_OPERATOR)
    {
        require(_pools.length == _rewards.length, Errors.LENGTH_MISMATCH());
        for (uint256 i; i < _pools.length; ++i) {
            voter.removeFeeDistributorReward(voter.feeDistributorForGauge(voter.gaugeForPool(_pools[i])), _rewards[i]);
        }
    }

    /**
     * LauncherPlugin specific functions
     */

    /// @inheritdoc IAccessHub
    function migratePoolInLauncherPlugin(address _oldPool, address _newPool) external onlyRole(PROTOCOL_OPERATOR) {
        launcherPlugin.migratePool(_oldPool, _newPool);
    }

    /// @inheritdoc IAccessHub
    function setConfigsInLauncherPlugin(address _pool, uint256 _take, address _recipient)
        external
        onlyRole(PROTOCOL_OPERATOR)
    {
        launcherPlugin.setConfigs(_pool, _take, _recipient);
    }

    /// @inheritdoc IAccessHub
    function enablePoolInLauncherPlugin(address _pool) external onlyRole(PROTOCOL_OPERATOR) {
        launcherPlugin.enablePool(_pool);
    }

    /// @inheritdoc IAccessHub
    function disablePoolInLauncherPlugin(address _pool) external onlyRole(PROTOCOL_OPERATOR) {
        launcherPlugin.disablePool(_pool);
    }

    /// @inheritdoc IAccessHub
    function setOperatorInLauncherPlugin(address _newOperator) external onlyRole(PROTOCOL_OPERATOR) {
        launcherPlugin.setOperator(_newOperator);
    }

    /// @inheritdoc IAccessHub
    function grantAuthorityInLauncherPlugin(address _newAuthority, string calldata _label)
        external
        onlyRole(PROTOCOL_OPERATOR)
    {
        launcherPlugin.grantAuthority(_newAuthority, _label);
    }

    /// @inheritdoc IAccessHub
    function labelAuthorityInLauncherPlugin(address _authority, string calldata _label)
        external
        onlyRole(PROTOCOL_OPERATOR)
    {
        launcherPlugin.label(_authority, _label);
    }

    /// @inheritdoc IAccessHub
    function revokeAuthorityInLauncherPlugin(address _oldAuthority) external onlyRole(PROTOCOL_OPERATOR) {
        launcherPlugin.revokeAuthority(_oldAuthority);
    }

    /**
     * FeeCollector functions
     */

    /// @inheritdoc IAccessHub
    function setTreasuryInFeeCollector(address newTreasury) external onlyRole(PROTOCOL_OPERATOR) {
        feeCollector.setTreasury(newTreasury);
    }

    /// @inheritdoc IAccessHub
    function setTreasuryFeesInFeeCollector(uint256 _treasuryFees) external onlyRole(PROTOCOL_OPERATOR) {
        feeCollector.setTreasuryFees(_treasuryFees);
    }

    /**
     * FeeRecipientFactory functions
     */

    /// @inheritdoc IAccessHub
    function setFeeToTreasuryInFeeRecipientFactory(uint256 _feeToTreasury) external onlyRole(PROTOCOL_OPERATOR) {
        feeRecipientFactory.setFeeToTreasury(_feeToTreasury);
    }

    /// @inheritdoc IAccessHub
    function setTreasuryInFeeRecipientFactory(address _treasury) external onlyRole(PROTOCOL_OPERATOR) {
        feeRecipientFactory.setTreasury(_treasury);
    }

    /**
     * CL Pool Factory functions
     */

    /// @inheritdoc IAccessHub
    function enableTickSpacing(int24 tickSpacing, uint24 initialFee) external onlyRole(PROTOCOL_OPERATOR) {
        shadowV3PoolFactory.enableTickSpacing(tickSpacing, initialFee);
    }

    /// @inheritdoc IAccessHub
    function setGlobalClFeeProtocol(uint8 _feeProtocolGlobal) external onlyRole(PROTOCOL_OPERATOR) {
        shadowV3PoolFactory.setFeeProtocol(_feeProtocolGlobal);
    }

    /// @inheritdoc IAccessHub
    /// @notice sets the address of the voter in the v3 factory for gauge fee setting
    function setVoterAddressInFactoryV3(address _voter) external timelocked {
        shadowV3PoolFactory.setVoter(_voter);
    }

    /// @inheritdoc IAccessHub
    function setFeeCollectorInFactoryV3(address _newFeeCollector) external timelocked {
        shadowV3PoolFactory.setFeeCollector(_newFeeCollector);
    }

    /**
     * Legacy Pool Factory functions
     */

    /// @inheritdoc IAccessHub
    function setTreasuryInLegacyFactory(address _treasury) external onlyRole(PROTOCOL_OPERATOR) {
        poolFactory.setTreasury(_treasury);
    }

    /// @inheritdoc IAccessHub
    function setFeeSplitWhenNoGauge(bool status) external onlyRole(PROTOCOL_OPERATOR) {
        poolFactory.setFeeSplitWhenNoGauge(status);
    }

    /// @inheritdoc IAccessHub
    function setLegacyFeeSplitGlobal(uint256 _feeSplit) external onlyRole(PROTOCOL_OPERATOR) {
        poolFactory.setFeeSplit(_feeSplit);
    }

    /// @inheritdoc IAccessHub
    function setLegacyFeeGlobal(uint256 _fee) external onlyRole(PROTOCOL_OPERATOR) {
        poolFactory.setFee(_fee);
    }

    /// @inheritdoc IAccessHub
    function setSkimEnabledLegacy(address _pair, bool _status) external onlyRole(PROTOCOL_OPERATOR) {
        poolFactory.setSkimEnabled(_pair, _status);
    }

    /**
     * VoteModule Functions
     */

    /// @inheritdoc IAccessHub
    function setCooldownExemption(address[] calldata _candidates, bool[] calldata _exempt) external timelocked {
        for (uint256 i; i < _candidates.length; ++i) {
            voteModule.setCooldownExemption(_candidates[i], _exempt[i]);
        }
    }

    /// @inheritdoc IAccessHub
    function setNewRebaseStreamingDuration(uint256 _newDuration) external timelocked {
        voteModule.setNewDuration(_newDuration);
    }

    /// @inheritdoc IAccessHub
    function setNewVoteModuleCooldown(uint256 _newCooldown) external timelocked {
        voteModule.setNewCooldown(_newCooldown);
    }

    /// @inheritdoc IAccessHub
    function kickInactive(address[] calldata _nonparticipants) external onlyRole(PROTOCOL_OPERATOR) {
        IVoter voterContract = IVoter(voter);
        uint256 nextPeriod = voterContract.getPeriod() + 1;

        /// @dev loop through all input addresses to check status of vote
        for (uint256 i; i < _nonparticipants.length; ++i) {
            /// @dev store for use
            address nonparticipant = _nonparticipants[i];
            /// @dev fetch data on current voting period (nextPeriod votes)
            (address[] memory _pools, uint256[] memory _weights) = voterContract.getVotes(nonparticipant, nextPeriod);

            /// @dev require the user has not voted this epoch
            require(_pools.length == 0 && _weights.length == 0, Errors.KICK_FORBIDDEN(nonparticipant));
            /// @dev reset the user's votes
            voterContract.reset(nonparticipant);
        }
    }

    /**
     * Timelock specific functions
     */

    /// @inheritdoc IAccessHub
    function execute(address _target, bytes calldata _payload) external timelocked {
        (bool success,) = _target.call(_payload);
        require(success, Errors.MANUAL_EXECUTION_FAILURE(_payload));
    }

    /// @inheritdoc IAccessHub
    function setNewTimelock(address _timelock) external timelocked {
        require(timelock != _timelock, Errors.SAME_ADDRESS());
        timelock = _timelock;
    }

    /// backup distribute method
    // function backupDistribute() external onlyRole(PROTOCOL_OPERATOR) {
    //     backupDistributeBatch(0, type(uint256).max);
    // }

    // function backupDistributeBatch(uint256 startIndex, uint256 batchSize) public onlyRole(PROTOCOL_OPERATOR) {
    //     address SHADOW = address(xShadow.SHADOW());

    //     /// force unpause xshadow if its already paused
    //     if (Pausable(address(xShadow)).paused()) {
    //         xShadow.unpause();
    //     }
    //     minter.updatePeriod();

    //     uint256 currentPeriod = voter.getPeriod();
    //     address[] memory gauges = voter.getAllGauges();
    //     uint256 totalRewardPerPeriod = voter.totalRewardPerPeriod(currentPeriod);
    //     uint256 totalVotesPerPeriod = voter.totalVotesPerPeriod(currentPeriod);

    //     uint256 endIndex = startIndex + batchSize;
    //     if (endIndex > gauges.length) {
    //         endIndex = gauges.length;
    //     }

    //     for (uint256 i = startIndex; i < endIndex; i++) {
    //         uint256 lastDistro = voter.lastDistro(gauges[i]);
    //         if (lastDistro == currentPeriod) {
    //             continue;
    //         }

    //         uint256 balanceInVoter = IERC20(SHADOW).balanceOf(address(voter));
    //         address pool = voter.poolForGauge(gauges[i]);
    //         uint256 poolVotes = voter.poolTotalVotesPerPeriod(pool, currentPeriod);
    //         uint256 numerator = totalRewardPerPeriod * poolVotes * 1e18;
    //         uint256 balanceNeeded = numerator == 0 ? 0 : numerator / totalVotesPerPeriod / 1e18;

    //         if (balanceNeeded > balanceInVoter) {
    //             IERC20(SHADOW).transfer(address(voter), balanceNeeded - balanceInVoter);
    //         }

    //         if (voter.isAlive(gauges[i])) {
    //             voter.killGauge(gauges[i]);
    //             voter.reviveGauge(gauges[i]);
    //         } else {
    //             voter.stuckEmissionsRecovery(gauges[i], currentPeriod);
    //         }
    //     }
    // }
    /// @dev allow distributing emissions via the accessHub

    function notifyEmissions(address[] calldata pools, uint256[] calldata emissions)
        external
        onlyRole(PROTOCOL_OPERATOR)
    {
        IERC20 SHADOW = IERC20(xShadow.SHADOW());
        SHADOW.approve(address(xShadow), SHADOW.balanceOf(address(this)));
        xShadow.convertEmissionsToken(SHADOW.balanceOf(address(this)));
        for (uint256 i; i < pools.length; ++i) {
            address pool = pools[i];
            address gauge = voter.gaugeForPool(pool);
            uint256 amount = emissions[i];
            xShadow.approve(gauge, amount);
            /// @dev both CL and legacy gauges have the same function so we can reuse the interface regardless
            IGaugeV3(gauge).notifyRewardAmount(address(xShadow), amount);
        }
    }

    /// @dev allow distributing voting incentives via the accessHub
    function notifyVotingIncentives(address[] calldata pools, uint256[] calldata incentives)
        external
        onlyRole(PROTOCOL_OPERATOR)
    {
        for (uint256 i; i < pools.length; ++i) {
            IFeeDistributor feeDistributorForPool =
                IFeeDistributor(voter.feeDistributorForGauge(voter.gaugeForPool(pools[i])));
            xShadow.approve(address(feeDistributorForPool), incentives[i]);
            feeDistributorForPool.incentivize(address(xShadow), incentives[i]);
        }
    }

    /// @dev allows us to distro gems and add them as rewards atomically
    function ahhhImGemming(address rewardToken, address[] calldata pools, uint256[] calldata gems)
        external
        onlyRole(PROTOCOL_OPERATOR)
    {
        require(pools.length == gems.length, "length");
        for (uint256 i; i < pools.length; ++i) {
            IGaugeV3 gauge = IGaugeV3(voter.gaugeForPool(pools[i]));
            IERC20(rewardToken).approve(address(gauge), gems[i]);
            voter.whitelistGaugeRewards(address(gauge), rewardToken);
            gauge.notifyRewardAmount(rewardToken, gems[i]);
        }
    }

    /// @dev allows fees to be minted from un-gauged legacy pairs
    function enableFeeSplitting(address pair, address token) external onlyRole(PROTOCOL_OPERATOR) {
        /// @dev whitelist to enable gauging
        voter.whitelist(token);
        /// @dev create the gauge temporarily
        voter.createGauge(pair);
        /// @dev kill to set feeRecipient to the governor
        voter.killGauge(voter.gaugeForPool(pair));
        /// @dev 5%
        poolFactory.setPairFeeSplit(pair, 500);
        /// @dev remove the token's whitelist status
        voter.revokeWhitelist(token);
    }

    function rescue(address token) external onlyRole(PROTOCOL_OPERATOR) {
        IERC20(token).transfer(treasury, IERC20(token).balanceOf(address(this)));
    }

    function rescueFromX33(address _token, uint256 _amount) external onlyRole(PROTOCOL_OPERATOR) {
        x33.rescue(_token, _amount);
    }
}
