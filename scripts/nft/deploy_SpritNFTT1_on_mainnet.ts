import { id } from "ethers/lib/utils";
import { ethers, upgrades } from "hardhat";
import {SpritNFTT1,SpritNFTT3} from  "../../typechain-types";

async function main(){
    const [owner,operator] = await ethers.getSigners();
    const spritNFTT1FTFactory = await ethers.getContractFactory("SpritNFTT1");
    const nft1 = (
        await spritNFTT1FTFactory.deploy(operator.address)
    ) as SpritNFTT1;
    await nft1.deployed();

    console.log("SpritNFTT1 address is:",nft1.address);

    const spritNFTT3FTFactory = await ethers.getContractFactory("SpritNFTT3");
    const nft3 = (
        await spritNFTT3FTFactory.deploy(operator.address)
    ) as SpritNFTT3;
    await nft1.deployed();

    console.log("SpritNFTT3 address is:",nft3.address);

}

main().catch(error => {
    console.log(error);
    process.exitCode = 1;
});

/**
 npx hardhat run ./scripts/nft/deploy_SpritNFTT1_on_mainnet.ts --network pijs

SpritNFTT1 address is: 0xcD5296a4b66EDea63Ed963bE9426ac15bc98C41b
SpritNFTT3 address is: 0xE26b1b686a919a5acE30525606b60BD57Af71611

 */