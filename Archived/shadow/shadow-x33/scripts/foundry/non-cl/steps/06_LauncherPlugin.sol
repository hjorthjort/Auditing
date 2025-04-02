// SPDX-License-Identifier: MIT
pragma solidity ^0.8.x;

import {LauncherPlugin} from "../../../../contracts/LauncherPlugin.sol";
import {LauncherPluginInstance} from "../instances/LauncherPluginInstance.sol";

library DeployLauncherPluginLibrary {
    function deploy(address voter, address accessHub, address operator)
        internal
        returns (LauncherPluginInstance memory)
    {
        LauncherPlugin launcherPlugin = new LauncherPlugin(voter, accessHub, operator);

        require(address(launcherPlugin.voter()) == voter, "Voter mismatch");
        require(launcherPlugin.accessHub() == accessHub, "AccessHub mismatch");
        require(launcherPlugin.operator() == operator, "Operator mismatch");

        return LauncherPluginInstance({
            launcherPlugin: address(launcherPlugin),
            voter: voter,
            accessHub: accessHub,
            operator: operator
        });
    }
}
