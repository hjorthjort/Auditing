import os
from datetime import datetime
from typing import List

import tomlkit
from dotenv import load_dotenv

load_dotenv()


def validate_env_file(chain: str):
    """
    Validates required environment variables for a specific chain.
    Raises ValueError if any required variables are missing.
    """
    required_vars = [
        "PRIVATE_KEY",
        f"{chain.upper()}_RPC",
        f"{chain.upper()}SCAN_URL",
        f"{chain.upper()}SCAN_API_KEY",
    ]

    missing = [var for var in required_vars if not os.getenv(var)]
    if missing:
        raise ValueError(
            f"❌ .ENV ERROR: Missing required environment variables: {', '.join(missing)}"
        )


def set_foundry_network(chain: str):
    """
    Modifies foundry.toml file ENV_VAR automatically

    (if chain="arbitrum" then "${SONIC_RPC}" -> "${ARBITRUM_RPC}")
    """
    with open("foundry.toml", "r") as f:
        config = tomlkit.load(f)

    config["rpc_endpoints"]["mainnet"] = f"${{{chain.upper()}_RPC}}"  # type: ignore

    with open("foundry.toml", "w") as f:
        tomlkit.dump(config, f)


def get_chain_rpc(chain: str) -> str:
    """Get RPC URL from environment variables for a given chain"""
    rpc = os.getenv(f"{chain.upper()}_RPC")
    assert rpc is not None  # `validate_env_file` should always catch this

    return rpc


class ForgeUtils:
    def __init__(self, chain: str):
        self.chain = chain
        validate_env_file(chain)
        self.rpc_url = get_chain_rpc(chain)
        self._set_network()
        self.command = self._get_base_command()

    def _get_base_command(self) -> str:
        return (
            "--broadcast "
            f"--rpc-url {self.rpc_url} "
            "--private-key $PRIVATE_KEY "
            "--verify "
            f"--verifier-url ${{{self.chain.upper()}SCAN_URL}} "
            f"--etherscan-api-key ${{{self.chain.upper()}SCAN_API_KEY}}"
        )

    def _set_network(self):
        set_foundry_network(self.chain)

    def create_contract(
        self,
        path: str,
        verify_config: str = "",
        constructor_args: List[str] = [],
    ) -> dict:
        """Creates a contract with constructor arguments"""
        args = " ".join(str(arg) for arg in constructor_args)
        command = f"forge create {path} {self.command} " + (
            f"--constructor-args {args}" if constructor_args else ""
        )
        return {"command": command, "verify_config": verify_config}

    def run_script(self, path: str, verify_config: str = "") -> dict:
        command = f"forge script {path} {self.command}"
        return {"command": command, "verify_config": verify_config}

    def generate_bash_script(
        self, commands: List[dict], output_file: str = "deploy.sh"
    ) -> None:
        """Generates a bash script with the deployment commands"""
        script_dir = os.path.dirname(os.path.abspath(__file__))
        output_path = os.path.join(script_dir, output_file)

        with open(output_path, "w", encoding="utf-8") as f:
            f.write("#!/bin/bash\n\n")

            timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            f.write(f"# Generated on: {timestamp}\n")
            f.write("# ----------------------------------------\n\n")

            f.write("# Load environment variables\n")
            f.write("source .env\n\n")

            f.write("# Function to verify configuration\n")
            f.write("verify_config() {\n")
            f.write('    if [ -n "$1" ]; then\n')
            f.write('        echo -e "\\n⚠️ $1"\n')
            f.write('        read -p "Press Enter to continue..."\n')
            f.write("    fi\n")
            f.write("}\n\n")

            for cmd_dict in commands:
                cmd = cmd_dict["command"]
                verify_msg = cmd_dict.get("verify_config", "")

                if verify_msg:
                    f.write(f'verify_config "{verify_msg}"\n')
                f.write(f"echo 'Executing: {cmd}'\n")
                f.write(f"{cmd}\n\n")

        # make the script executable
        os.chmod(output_path, 0o755)
        print(f"🎉 Deployment script generated: {output_path}")
        print(f"Generated on: {timestamp}")
        print(f"Run it with: ./{output_path}")
