// SPDX-License-Identifier: MIT
pragma solidity ^0.8.x;

import {VoteModule} from "../../../../contracts/VoteModule.sol";
import {VoteModuleInstance} from "../instances/VoteModuleInstance.sol";
import {IXShadow} from "../../../../contracts/interfaces/IXShadow.sol";

library DeployVoteModuleLibrary {
    function deploy() internal returns (VoteModuleInstance memory) {
        VoteModule voteModule = new VoteModule();

        return VoteModuleInstance({voteModule: address(voteModule)});
    }

    function initialize(address voteModule, address xShadow, address voter, address accessHub) internal {
        VoteModule(voteModule).initialize(xShadow, voter, accessHub);
    }
}
