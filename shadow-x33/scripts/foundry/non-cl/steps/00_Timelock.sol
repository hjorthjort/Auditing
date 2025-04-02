// SPDX-License-Identifier: MIT
pragma solidity ^0.8.x;

import {TimeLock} from "../../../../contracts/TimeLock.sol";
import {TimelockInstance} from "../instances/TimelockInstance.sol";

library TimelockDeployLibrary {
    function deploy(address admin, uint256 minDelay, address[] memory proposers, address[] memory executors)
        internal
        returns (TimelockInstance memory)
    {
        // Deploy timelock with admin as proposer and executor
        TimeLock timelock = new TimeLock(
            minDelay,
            proposers,
            executors,
            admin // Admin address
        );

        require(timelock.getMinDelay() == minDelay, "Min delay mismatch");
        // Check proposers have PROPOSER_ROLE
        for (uint256 i = 0; i < proposers.length; i++) {
            require(timelock.hasRole(timelock.PROPOSER_ROLE(), proposers[i]), "Proposer missing role");
        }

        // Check executors have EXECUTOR_ROLE
        for (uint256 i = 0; i < executors.length; i++) {
            require(timelock.hasRole(timelock.EXECUTOR_ROLE(), executors[i]), "Executor missing role");
        }

        // Check admin has DEFAULT_ADMIN_ROLE
        require(timelock.hasRole(timelock.DEFAULT_ADMIN_ROLE(), admin), "Admin missing role");

        return TimelockInstance({
            timelock: address(timelock),
            admin: admin,
            minDelay: minDelay,
            proposers: proposers,
            executors: executors
        });
    }

    function replaceAdmin(TimelockInstance memory timelock, address newAdmin) internal {
        timelock.admin = newAdmin;
        TimeLock timelockController = TimeLock(payable(timelock.timelock));
        timelockController.grantRole(timelockController.DEFAULT_ADMIN_ROLE(), newAdmin);
        timelockController.renounceRole(timelockController.DEFAULT_ADMIN_ROLE(), address(timelock.admin));
    }

    function addProposer(TimelockInstance memory timelock, address newProposer) internal {
        TimeLock timelockController = TimeLock(payable(timelock.timelock));
        timelockController.grantRole(timelockController.PROPOSER_ROLE(), newProposer);
    }

    function addExecutor(TimelockInstance memory timelock, address newExecutor) internal {
        TimeLock timelockController = TimeLock(payable(timelock.timelock));
        timelockController.grantRole(timelockController.EXECUTOR_ROLE(), newExecutor);
    }

    function removeProposer(TimelockInstance memory timelock, address oldProposer) internal {
        TimeLock timelockController = TimeLock(payable(timelock.timelock));
        timelockController.revokeRole(timelockController.PROPOSER_ROLE(), oldProposer);
    }

    function removeExecutor(TimelockInstance memory timelock, address oldExecutor) internal {
        TimeLock timelockController = TimeLock(payable(timelock.timelock));
        timelockController.revokeRole(timelockController.EXECUTOR_ROLE(), oldExecutor);
    }
}
