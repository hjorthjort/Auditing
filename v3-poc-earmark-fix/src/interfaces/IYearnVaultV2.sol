// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

import "../../lib/openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";

/// @title  IYearnVaultV2
/// @author Yearn Finance
interface IYearnVaultV2 is IERC20Metadata {
    struct StrategyParams {
        uint256 performanceFee;
        uint256 activation;
        uint256 debtRatio;
        uint256 minDebtPerHarvest;
        uint256 maxDebtPerHarvest;
        uint256 lastReport;
        uint256 totalDebt;
        uint256 totalGain;
        uint256 totalLoss;
        bool enforceChangeLimit;
        uint256 profitLimitRatio;
        uint256 lossLimitRatio;
        address customCheck;
    }

    function apiVersion() external pure returns (string memory);

    function permit(address owner, address spender, uint256 amount, uint256 expiry, bytes calldata signature) external returns (bool);

    // NOTE: Vyper produces multiple signatures for a given function with "default" args
    function deposit() external returns (uint256);

    function deposit(uint256 amount) external returns (uint256);

    function deposit(uint256 amount, address recipient) external returns (uint256);

    // NOTE: Vyper produces multiple signatures for a given function with "default" args
    function withdraw() external returns (uint256);

    function withdraw(uint256 maxShares) external returns (uint256);

    function withdraw(uint256 maxShares, address recipient) external returns (uint256);

    function withdraw(uint256 maxShares, address recipient, uint256 maxLoss) external returns (uint256);

    function token() external view returns (address);

    function strategies(address _strategy) external view returns (StrategyParams memory);

    function pricePerShare() external view returns (uint256);

    function totalAssets() external view returns (uint256);

    function depositLimit() external view returns (uint256);

    function maxAvailableShares() external view returns (uint256);

    /// @notice View how much the Vault would increase this Strategy's borrow limit, based on its present performance
    ///         (since its last report). Can be used to determine expectedReturn in your Strategy.
    function creditAvailable() external view returns (uint256);

    /// @notice View how much the Vault would like to pull back from the Strategy, based on its present performance
    ///         (since its last report). Can be used to determine expectedReturn in your Strategy.
    function debtOutstanding() external view returns (uint256);

    /// @notice View how much the Vault expect this Strategy to return at the current block, based on its present
    ///         performance (since its last report). Can be used to determine expectedReturn in your Strategy.
    function expectedReturn() external view returns (uint256);

    /// @notice This is the main contact point where the Strategy interacts with the Vault. It is critical that this call
    ///         is handled as intended by the Strategy. Therefore, this function will be called by BaseStrategy to make
    ///         sure the integration is correct.
    function report(uint256 _gain, uint256 _loss, uint256 _debtPayment) external returns (uint256);

    /// @notice This function should only be used in the scenario where the Strategy is being retired but no migration of
    ///         the positions are possible, or in the extreme scenario that the Strategy needs to be put into
    ///         "Emergency Exit" mode in order for it to exit as quickly as possible. The latter scenario could be for any
    ///         reason that is considered "critical" that the Strategy exits its position as fast as possible, such as a
    ///         sudden change in market conditions leading to losses, or an imminent failure in an external dependency.
    function revokeStrategy() external;

    /// @notice View the governance address of the Vault to assert privileged functions can only be called by governance.
    ///         The Strategy serves the Vault, so it is subject to governance defined by the Vault.
    function governance() external view returns (address);

    /// @notice View the management address of the Vault to assert privileged functions can only be called by management.
    ///         The Strategy serves the Vault, so it is subject to management defined by the Vault.
    function management() external view returns (address);

    /// @notice View the guardian address of the Vault to assert privileged functions can only be called by guardian. The
    ///         Strategy serves the Vault, so it is subject to guardian defined by the Vault.
    function guardian() external view returns (address);
}
