// SPDX-License-Identifier: MIT
pragma solidity ^0.8.x;

import {Voter} from "../../../../contracts/Voter.sol";
import {VoterInstance} from "../instances/VoterInstance.sol";
import {VoterSetInstance} from "../instances/VoterSetInstance.sol";

library VoterDeployLibrary {
    function deploy(address accessHub) internal returns (VoterInstance memory) {
        Voter voter = new Voter(accessHub);

        return VoterInstance({voter: address(voter)});
    }

    function initialize(address voter, VoterSetInstance memory setInstance) internal {
        Voter(voter).initialize(
            setInstance.shadow,
            setInstance.legacyFactory,
            setInstance.gauges,
            setInstance.feeDistributorFactory,
            setInstance.minter,
            setInstance.msig,
            setInstance.xShadow,
            setInstance.clFactory,
            setInstance.clGaugeFactory,
            setInstance.nfpManager,
            setInstance.feeRecipientFactory,
            setInstance.voteModule,
            setInstance.launcherPlugin
        );

        require(address(Voter(voter).shadow()) == setInstance.shadow, "EmissionsToken mismatch");
        require(address(Voter(voter).legacyFactory()) == setInstance.legacyFactory, "LegacyFactory mismatch");
        require(address(Voter(voter).gaugeFactory()) == setInstance.gauges, "GaugeFactory mismatch");
        require(
            address(Voter(voter).feeDistributorFactory()) == setInstance.feeDistributorFactory,
            "FeeDistributorFactory mismatch"
        );
        require(address(Voter(voter).minter()) == setInstance.minter, "Minter mismatch");
        require(address(Voter(voter).xShadow()) == setInstance.xShadow, "xShadow mismatch");
        require(address(Voter(voter).governor()) == setInstance.msig, "Governor mismatch");
        require(
            address(Voter(voter).feeRecipientFactory()) == setInstance.feeRecipientFactory,
            "FeeRecipientFactory mismatch"
        );
        require(address(Voter(voter).voteModule()) == setInstance.voteModule, "VoteModule mismatch");
        require(address(Voter(voter).launcherPlugin()) == setInstance.launcherPlugin, "LauncherPlugin mismatch");
        require(address(Voter(voter).clFactory()) == setInstance.clFactory, "CLFactory mismatch");
        require(address(Voter(voter).clGaugeFactory()) == setInstance.clGaugeFactory, "CLGaugeFactory mismatch");
        require(address(Voter(voter).nfpManager()) == setInstance.nfpManager, "NFPManager mismatch");
        require(Voter(voter).xRatio() == 1_000_000, "xRatio mismatch");
    }
}
