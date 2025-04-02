// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

struct AccessHubSetInstance {
    address timelock;
    address treasury;
    address voter;
    address minter;
    address launcherPlugin;
    address xShadow;
    address x33;
    address shadowV3PoolFactory;
    address poolFactory;
    address clGaugeFactory;
    address gaugeFactory;
    address feeRecipientFactory;
    address feeDistributorFactory;
    address feeCollector;
    address voteModule;
}
