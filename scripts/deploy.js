const hre = require("hardhat");

async function main() {
    const Election = await hre.ethers.getContractFactory("Election");
    const election_ = await Election.deploy();

    await election_.deployed();

    console.log(
        `Contract Address: ${election_.address}`
    );
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
