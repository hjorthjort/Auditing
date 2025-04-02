import os
from datetime import datetime

from dotenv import load_dotenv
from eth_utils.address import to_checksum_address
from multicall import Call
from rich.console import Console
from rich.panel import Panel
from rich.table import Table
from rich.text import Text
from web3 import Web3
from web3.exceptions import ContractLogicError

load_dotenv()
console = Console()
validation_results = []


def validate_address(actual, expected_address, source_contract=None):
    # double checksum for 1:1 comparison
    actual = to_checksum_address(actual)
    expected_address = to_checksum_address(expected_address)

    name = next(
        name
        for name, addr in DEPLOYMENT_ADDRESSES.items()
        if addr.lower() == expected_address.lower()
    )
    result = {
        "contract": name,
        "status": "❌" if actual != expected_address else "✅",
        "actual": actual,
        "expected": expected_address,
        "source": source_contract,
    }
    validation_results.append(result)
    return actual == expected_address


def validate_contract_addresses(
    contract_address: str, validations: dict, source_name: str
):
    """
    Validate multiple contract addresses against their expected values
    Args:
        contract_address: The address of the contract to check
        validations: Dict of {function_name: expected_contract_name}
        source_name: Name of the contract initiating the validation
    """
    all_valid = True
    for func_name, expected_contract_name in validations.items():
        is_valid = validate_address(
            Call(contract_address, f"{func_name}()(address)", _w3=w3)(),
            DEPLOYMENT_ADDRESSES[expected_contract_name],
            source_name,
        )
        all_valid = all_valid and is_valid
    return all_valid


def check_contracts_bytecode():
    print("🔍 Validating contract code...")
    all_valid = True
    for name, address in DEPLOYMENT_ADDRESSES.items():
        code = w3.eth.get_code(address)  # type: ignore
        if code == b"":
            print(f"❌ Contract {name} at {address} has no code (is it an EOA?)")
            all_valid = False
    if all_valid:
        print("✅ All contracts have code")
    else:
        raise Exception("❌ Some contracts have no code (possible EOA)")


def check_voter():
    validations = [
        "legacyFactory",
        "xShadow",
        "minter",
        "accessHub",
        "voteModule",
        "launcherPlugin",
        "clFactory",
        "clGaugeFactory",
        "gaugeFactory",
        "feeDistributorFactory",
        "feeRecipientFactory",
        "nfpManager",
        "governor",
    ]

    print("🔍 Validating Voter...")
    if validate_contract_addresses(
        DEPLOYMENT_ADDRESSES["voter"], {name: name for name in validations}, "Voter"
    ):
        print("✅ Voter checks passed")
    else:
        print("❌ Voter has invalid addresses")


def check_cl_gauge_factory():
    validations = ["nfpManager", "voter", "feeCollector"]

    print("🔍 Validating ClGaugeFactory...")
    if validate_contract_addresses(
        DEPLOYMENT_ADDRESSES["clGaugeFactory"],
        {name: name for name in validations},
        "ClGaugeFactory",
    ):
        print("✅ ClGaugeFactory checks passed")
    else:
        print("❌ ClGaugeFactory has invalid addresses")


def check_access_hub():
    validations = [
        "timelock",
        "treasury",
        "clGaugeFactory",
        "gaugeFactory",
        "feeDistributorFactory",
        "voter",
        "minter",
        "launcherPlugin",
        "xShadow",
        "shadowV3PoolFactory",
        "poolFactory",
        "feeRecipientFactory",
        "feeCollector",
        "voteModule",
    ]

    print("🔍 Validating AccessHub...")
    if validate_contract_addresses(
        DEPLOYMENT_ADDRESSES["accessHub"],
        {name: name for name in validations},
        "AccessHub",
    ):
        print("✅ AccessHub checks passed")
    else:
        print("❌ AccessHub has invalid addresses")


def check_cl_factory():
    validations = ["accessHub", "feeCollector", "shadowV3PoolDeployer", "voter"]

    print("🔍 Validating CLFactory...")
    if validate_contract_addresses(
        DEPLOYMENT_ADDRESSES["clFactory"],
        {name: name for name in validations},
        "ClFactory",
    ):
        print("✅ CLFactory checks passed")
    else:
        print("❌ CLFactory has invalid addresses")


def print_validation_report():
    console.print(
        "\n[bold white]Contract Validation Report[/bold white]", justify="center"
    )

    table = Table(show_header=True, header_style="bold magenta")
    table.add_column("Status", justify="center", width=6)
    table.add_column("Source", style="yellow")
    table.add_column("Contract", style="dim")
    table.add_column("Actual Address", style="cyan")
    table.add_column("Expected Address", style="green")

    for result in validation_results:
        table.add_row(
            result["status"],
            result.get("source", "Unknown"),
            result["contract"],
            result["actual"],
            result["expected"],
        )

    console.print(table)

    # Summary
    total = len(validation_results)
    failed = sum(1 for r in validation_results if r["status"] == "❌")
    passed = total - failed

    summary = Text()
    summary.append(f"\nTotal Validations: {total}\n", style="bold")
    summary.append(f"Passed: {passed} ", style="green")
    summary.append(f"Failed: {failed}", style="red")

    console.print(Panel(summary, title="Summary", border_style="blue"))


if __name__ == "__main__":
    # config
    DEPLOYMENT_ADDRESSES = {
        "feeCollector": "0xcc0365F8f453C55EA7471C9F89767928c8f8d27F",
        "clGaugeFactory": "0xf914Cc768040B4268A779C3084a3E9cdA6E8a1A8",
        "router": "0x1D368773735ee1E678950B7A97bcA2CafB330CDc",
        "xShadow": "0x5050bc082FF4A74Fb6B0B04385dEfdDB114b2424",
        "minter": "0xc7022F359cD1bDa8aB8a19d1F19d769cbf7F3765",
        "feeDistributorFactory": "0x29aDF08a22381855243eeeb3228647aC56847Ff5",
        "feeRecipientFactory": "0x5712bD693aC758158146aa151F31BD74CFBF37c1",
        "gaugeFactory": "0x8CF82D413cA20a40a2Fa43C2bF77D136d81299e9",
        "launcherPlugin": "0x3eC4fC1885513D932F113F9De9B50a8764dBfc7f",
        "legacyFactory": "0x2dA25E7446A70D7be65fd4c053948BEcAA6374c8",  # 1️⃣ alias for legacyFactory
        "poolFactory": "0x2dA25E7446A70D7be65fd4c053948BEcAA6374c8",  # 2️⃣ alias for legacyFactory
        "shadow": "0x3333b97138D4b086720b5aE8A7844b1345a33333",
        "voter": "0x3aF1dD7A2755201F8e2D6dCDA1a61d9f54838f4f",
        "accessHub": "0x5e7A9eea6988063A4dBb9CcDDB3E04C923E8E37f",
        "timelock": "0x4577D5d9687Ee4413Fc0c391b85861F0a383Df50",
        "proxyAdmin": "0x0E03b0A37B1C5c1D9800B758Ccb5b8E229690Dcf",
        "governor": "0x5Be2e859D0c2453C9aA062860cA27711ff553432",  # 1️⃣ alias for treasury
        "treasury": "0x5Be2e859D0c2453C9aA062860cA27711ff553432",  # 2️⃣ alias for treasury
        "multisig": "0x5Be2e859D0c2453C9aA062860cA27711ff553432",  # 3️⃣ alias for treasury
        "clFactory": "0xcD2d0637c94fe77C2896BbCBB174cefFb08DE6d7",  # 1️⃣ alias for clFactory
        "shadowV3PoolFactory": "0xcD2d0637c94fe77C2896BbCBB174cefFb08DE6d7",  # 2️⃣ alias for clFactory
        "nfpManager": "0x12E66C8F215DdD5d48d150c8f46aD0c6fB0F4406",
        "shadowV3PoolDeployer": "0x8BBDc15759a8eCf99A92E004E0C64ea9A5142d59",
        "voteModule": "0xDCB5A24ec708cc13cee12bFE6799A78a79b666b4",
    }

    w3 = Web3(Web3.HTTPProvider(os.getenv("SONIC_RPC")))

    # check if all contracts have code
    check_contracts_bytecode()
    # address checks
    check_cl_gauge_factory()
    check_voter()
    check_access_hub()
    check_cl_factory()

    # final report
    print_validation_report()
