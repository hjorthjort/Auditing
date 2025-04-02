import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "@openzeppelin/hardhat-upgrades";

import { resolve } from "path";
import { config as dotenvConfig } from "dotenv";
dotenvConfig({ path: resolve(__dirname, "./.env") });

import "hardhat-contract-sizer";
import "@nomiclabs/hardhat-solhint";
//import "@nomicfoundation/hardhat-ignition-ethers";
//import "@nomicfoundation/hardhat-foundry";

const POOL_COMPILER_SETTINGS = {
    version: "0.8.26",
    settings: {
        viaIR: true,
        optimizer: {
            enabled: true,
            runs: 800,
        },
        evmVersion: "cancun",
        metadata: {
            bytecodeHash: "none",
        },
    },
};

const accounts = process.env.PRIVATE_KEY
    ? [process.env.PRIVATE_KEY]
    : undefined;

const voterCompilerSettings = {
    version: "0.8.28",
    settings: {
        optimizer: {
            enabled: true,
            runs: 420,
        },
        evmVersion: "cancun",
        viaIR: true,
        metadata: {
            bytecodeHash: "none",
        },
    },
};

const poolDeployerCompilerSettings = {
    version: "0.8.28",
    settings: {
        optimizer: {
            enabled: true,
            runs: 933,
        },
        evmVersion: "cancun",
        viaIR: true,
        // metadata: {
        //     bytecodeHash: "none",
        // },
    },
};

const config: HardhatUserConfig = {
    solidity: {
        compilers: [
            {
                version: "0.4.18",
                settings: {
                    optimizer: {
                        enabled: true,
                        runs: 930,
                    },
                    evmVersion: "cancun",
                    metadata: {
                        bytecodeHash: "none",
                    },
                },
            },
            // {
            //     version: "0.8.26",
            //     settings: {
            //         optimizer: {
            //             enabled: true,
            //             runs: 800,
            //         },
            //         viaIR: true,
            //         metadata: {
            //             // do not include the metadata hash, since this is machine dependent
            //             // and we want all generated code to be deterministic
            //             // https://docs.soliditylang.org/en/v0.7.6/metadata.html
            //             bytecodeHash: "none",
            //         },
            //     },
            // },
            {
                version: "0.8.28",
                settings: {
                    optimizer: {
                        enabled: true,
                        runs: 933,
                    },
                    evmVersion: "cancun",
                    viaIR: true,
                    // metadata: {
                    //     bytecodeHash: "none",
                    // },
                },
            },
            // {
            //     version: "0.8.17",

            // }
        ],
        overrides: {
            "contracts/Voter.sol": voterCompilerSettings,
            "contracts/libraries/RewardClaimers.sol": voterCompilerSettings,
            "contracts/CL/core/ShadowV3PoolDeployer.sol":
                poolDeployerCompilerSettings,
        },
    },

    networks: {
        hardhat: {
            chainId: 250,
            initialBaseFeePerGas: 0,
            allowUnlimitedContractSize: true,
        },
        localhost: {
            accounts: accounts,
        },
        fantom: {
            url: process.env.RPC ?? "https://rpc3.fantom.network",
            accounts: accounts,
        },
        sonic: {
            url: process.env.RPC ?? "https://rpc.soniclabs.com",
            accounts: accounts,
            chainId: 146,
        },
    },

    etherscan: {
        apiKey: {
            fantom: process.env.API_KEY!,
            sonic: "8U357IVK3R6N9CZ7YCH95KCVXWMG4SB47C",
        },
        customChains: [
            {
                network: "sonic",
                chainId: 146,
                urls: {
                    apiURL: "https://api.sonicscan.org/api",
                    browserURL: "https://sonicscan.org",
                },
            },
        ],
    },

    gasReporter: {
        enabled: process.env.REPORT_GAS?.toLowerCase() == "true",
    },

    paths: {
        sources: "contracts/CL/core",
        tests: "test/v3",
    },
};

export default config;
