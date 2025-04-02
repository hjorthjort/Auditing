import os
import sys
from typing import List

project_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.append(project_root)

from deploy_helper.utils import (  # noqa: E402
    ForgeUtils,
    get_chain_rpc,
    validate_env_file,
)


class DeployHelper:
    def __init__(self, chain: str):
        self.chain = chain
        validate_env_file(chain)
        self.rpc_url = get_chain_rpc(chain)
        self.forge = ForgeUtils(chain)

    def deploy_access_hub(self, admin_address: str, timelock_address: str) -> dict:
        return self.forge.create_contract(
            path="contracts/AccessHub.sol:AccessHub",
            constructor_args=[admin_address, timelock_address],
        )

    def deploy_cl_full(self) -> dict:
        return self.forge.run_script(
            "scripts/foundry/cl/core/deployCLFull.sol:DeployCLFull",
            verify_config="verify `scripts/foundry/cl/core/config/mainnet.json`",
        )

    def deploy_periphery_full(self) -> dict:
        return self.forge.run_script(
            "scripts/foundry/cl/periphery/deployPeripheryFull.sol:DeployPeripheryFull",
            verify_config="verify `scripts/foundry/cl/periphery/config/mainnet.json`",
        )

    def deploy_mixed_route_quoter(
        self, v3_factory: str, legacy_factory: str
    ) -> dict:
        return self.forge.create_contract(
            "contracts/CL/periphery/lens/MixedRouteQuoterV1.sol:MixedRouteQuoterV1",
            constructor_args=[v3_factory, legacy_factory],
        )

    def deploy_universal_router(
        self,
        permit2: str,
        weth9: str,
        v2_factory: str,
        v3_factory: str,
        v2_init_code_hash: str,
        v3_init_code_hash: str,
    ) -> dict:
        return self.forge.run_script(
            f"test/gigasifu/deployUniversalRouter.s.sol:DeployUniversalRouter "
            f"-s run "
            f"{permit2} "
            f"{weth9} "
            f"{v2_factory} "
            f"{v3_factory} "
            f"{v2_init_code_hash} "
            f"{v3_init_code_hash}"
        )

    def generate_deploy_script(self, instructions: List[dict]) -> None:
        self.forge.generate_bash_script(instructions)


if __name__ == "__main__":
    helper = DeployHelper("sonic")

    instructions = [
        helper.deploy_universal_router(
            permit2="0x000000000022D473030F116dDEE9F6B43aC78BA3",
            weth9="0x039e2fB66102314Ce7b64Ce5Ce3E5183bc94aD38",
            v2_factory="0x0000000000000000000000000000000000000000",
            v3_factory="0xcD2d0637c94fe77C2896BbCBB174cefFb08DE6d7",
            v2_init_code_hash="0x0000000000000000000000000000000000000000000000000000000000000000",
            v3_init_code_hash="0xc701ee63862761c31d620a4a083c61bdc1e81761e6b9c9267fd19afd22e0821d",
        ),
        helper.deploy_mixed_route_quoter(
            "0xcD2d0637c94fe77C2896BbCBB174cefFb08DE6d7",
            "0x0000000000000000000000000000000000000000",
        ),
        # add more commands as needed
    ]

    # generate the bash script
    helper.generate_deploy_script(instructions)
