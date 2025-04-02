import { ethers } from "hardhat";
import * as helpers from "@nomicfoundation/hardhat-network-helpers";
import { setERC20Balance } from "../utils/helpers.ts";

async function main() {
    // this test starts at 11:59UTC
    // await helpers.reset("https://rpc.soniclabs.com", 5836388);
    await helpers.reset("https://rpc.soniclabs.com", 6715176);

    const [owner] = await ethers.getSigners();

    // https://github.com/NomicFoundation/hardhat/issues/5511#issuecomment-2288072104
    await helpers.mine();

    const randomWhale = await ethers.getImpersonatedSigner(
        "0x5050bc082FF4A74Fb6B0B04385dEfdDB114b2424",
    );

    await helpers.setBalance(randomWhale.address, ethers.parseEther("100"));

    const voter = await ethers.getContractAt(
        "Voter",
        "0x3af1dd7a2755201f8e2d6dcda1a61d9f54838f4f",
    );

    console.log("Deploying DustSwapper");
    const dustSwapper = await ethers.deployContract("DustSwapper");

    console.log("Updating records");
    await dustSwapper.updateRecords();

    const poolAddress = "0x2C13383855377faf5A562F1AeF47E4be7A0f12Ac";
    const pool = await ethers.getContractAt("ShadowV3Pool", poolAddress);
    console.log("lastPeriod before", await pool.lastPeriod());

    console.log("Determining Pool Index");
    const clPools = (await dustSwapper.getAllClPools()).map((element) => {
        return element.toLowerCase();
    });

    const poolIndex = clPools.indexOf(poolAddress.toLowerCase());

    console.log("errors identifiers");
    console.log("LOK", pool.interface.getError("LOK")?.selector);
    console.log("TLU", pool.interface.getError("TLU")?.selector);
    console.log("TLM", pool.interface.getError("TLM")?.selector);
    console.log("AI", pool.interface.getError("AI")?.selector);
    console.log("M0", pool.interface.getError("M0")?.selector);
    console.log("M1", pool.interface.getError("M1")?.selector);
    console.log("AS", pool.interface.getError("AS")?.selector);
    console.log("IIA", pool.interface.getError("IIA")?.selector);
    console.log("L", pool.interface.getError("L")?.selector);
    console.log("F0", pool.interface.getError("F0")?.selector);
    console.log("F1", pool.interface.getError("F1")?.selector);
    console.log("SPL", pool.interface.getError("SPL")?.selector);

    console.log("Pool index", poolIndex);

    console.log("Finding all tokens needed");

    const wSAddress = "0x039e2fB66102314Ce7b64Ce5Ce3E5183bc94aD38";
    const shadowAddress = "0x3333b97138D4b086720b5aE8A7844b1345a33333";
    const usdceAddress = "0x29219dd400f2Bf60E5a23d13Be72B486D4038894";
    const scEthAddress = "0x3bcE5CB273F0F148010BbEa2470e7b5df84C7812";
    const scUsdAddress = "0xd3DCe716f3eF535C5Ff8d041c1A41C3bd89b97aE";
    const wethAddress = "0x50c42dEAcD8Fc9773493ED674b675bE577f2634b";
    const _tokens: string[] = [
        wSAddress,
        shadowAddress,
        scEthAddress,
        usdceAddress,
        scUsdAddress,
        // wethAddress,
    ];
    await Promise.all(
        clPools.map(async (_poolAddress) => {
            const _pool = await ethers.getContractAt(
                "ShadowV3Pool",
                _poolAddress,
            );
            const token0 = await _pool.token0();
            const token1 = await _pool.token1();

            if (!_tokens.includes(token0) && !_tokens.includes(token1)) {
                _tokens.push(token0);
                _tokens.push(token1);
            }
        }),
    );
    const uniqueTokens = _tokens.filter((value, index, array) => {
        return array.indexOf(value) === index;
    });
    console.log("uniqueTokens", uniqueTokens);
    console.log("uniqueTokens length", uniqueTokens.length);

    console.log("Adding all unique tokens");

    await Promise.all(
        uniqueTokens.map(async (_tokenAddress) => {
            await setERC20Balance(
                _tokenAddress,
                await dustSwapper.getAddress(),
                ethers.parseEther("1"),
            );
            console.log(_tokenAddress);
        }),
    );

    // await helpers.time.increaseTo(1738195188);
    // await helpers.time.increaseTo(1738195200);
    await helpers.time.increase(86400 * 7);

    console.log("findNotUpdated before", await dustSwapper.findNotUpdated());

    console.log("Swapping Dust");
    console.log(
        "Missing tokens",
        await dustSwapper.findMissing.staticCallResult(),
    );
    await dustSwapper.swapDust(0, 9999999n, false, false);
    console.log("findNotUpdated after", await dustSwapper.findNotUpdated());

    console.log("lastPeriod after", await pool.lastPeriod());

    console.log("Missing Seeds", await dustSwapper.seed.staticCall(9, 12));
    await dustSwapper.seed(0, 9999999n);

    console.log("Check if selected pool is seeded");
    const newTokenId = await dustSwapper.poolToNfp(pool.getAddress());
    console.log("seed nfp tokenId", newTokenId);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
