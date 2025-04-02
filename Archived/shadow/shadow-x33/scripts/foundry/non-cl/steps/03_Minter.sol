// SPDX-License-Identifier: MIT
pragma solidity ^0.8.x;

import {Minter} from "../../../../contracts/Minter.sol";
import {MinterInstance} from "../instances/MinterInstance.sol";

library MinterDeployLibrary {
    function deploy(address accessHub, address operator) internal returns (MinterInstance memory) {
        Minter minter = new Minter(accessHub, operator);

        require(minter.accessHub() == accessHub, "AccessHub mismatch");
        require(minter.operator() == operator, "Operator mismatch");

        return MinterInstance({accessHub: accessHub, operator: operator, minter: address(minter)});
    }

    function kickoff(
        MinterInstance memory instance,
        address shadow,
        address voter,
        uint256 initialWeeklyEmissions,
        uint256 initialMultiplier,
        address xShadow
    ) internal {
        Minter(instance.minter).kickoff(shadow, voter, initialWeeklyEmissions, initialMultiplier, xShadow);
    }
}
