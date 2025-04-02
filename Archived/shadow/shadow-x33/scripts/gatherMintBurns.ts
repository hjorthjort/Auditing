import { deploy } from "../utils/deployment";
import { MainConfig } from "../utils/configs";
import fs from "fs";
import { ethers } from "hardhat";

// replace this block number with the block when 0:00 UTC happened
const startBlock = 7613938;

async function main() {
    const voter = await ethers.getContractAt(
        "Voter",
        "0x3aF1dD7A2755201F8e2D6dCDA1a61d9f54838f4f",
    );
    const gauges = await voter.getAllGauges();
    const pools: string[] = [];
    await Promise.all(
        gauges.map(async (element) => {
            const isClGauge = await voter.isClGauge(element);
            if (isClGauge) {
                pools.push(await voter.poolForGauge(element));
            }
        }),
    );

    await Promise.all(
        pools.map(async (element) => {
            const pool = await ethers.getContractAt("ShadowV3Pool", element);
            const mintFilter = pool.filters.Mint();
            const burnFilter = pool.filters.Burn();
            const swapFilter = pool.filters.Swap();
            const swaps = (
                await pool.queryFilter(
                    swapFilter,
                    startBlock,
                    startBlock + 10000,
                )
            ).sort((a, b) => {
                return a.blockNumber - b.blockNumber;
            });

            const mints = await pool.queryFilter(
                mintFilter,
                startBlock,
                swaps[0]?.blockNumber ?? startBlock + 10000,
            );
            if (mints.length > 0) {
                console.log("pool:", element);
                console.log("gauge:", await voter.gaugeForPool(element));
                console.log("swapBlock:", swaps[0]?.blockNumber ?? "none");
                console.log("swapHash:", swaps[0]?.transactionHash ?? "none");
                console.log("mintBlock:", mints[0].blockNumber);
                console.log("mintHash:", mints[0].transactionHash);
            }
            const burns = await pool.queryFilter(
                burnFilter,
                startBlock,
                swaps[0]?.blockNumber ?? startBlock + 10000,
            );

            if (burns.length > 0) {
                console.log("pool:", element);
                console.log("gauge:", await voter.gaugeForPool(element));
                console.log("swapBlock:", swaps[0]?.blockNumber ?? "none");
                console.log("swapHash:", swaps[0]?.transactionHash ?? "none");
                console.log("burnBlock:", burns[0].blockNumber);
                console.log("burnHash:", burns[0].transactionHash);
            }

            if (swaps.length == 0) {
                console.log("missing swap", await pool.getAddress());
            }
        }),
    );

    console.log("finished");
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
