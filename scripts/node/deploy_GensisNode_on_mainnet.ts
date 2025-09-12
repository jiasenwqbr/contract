import { id } from "ethers/lib/utils";
import { ethers, upgrades } from "hardhat";
import {GenesisNode} from  "../../typechain-types";

async function main(){
    const [owner,operator] = await ethers.getSigners();
    const genesisNFTFactory = await ethers.getContractFactory("GenesisNode");
    const nft = (
        await genesisNFTFactory.deploy(operator.address)
    ) as GenesisNode;
    await nft.deployed();

    console.log("GenesisNode address is:",nft.address);

}

main().catch(error => {
    console.log(error);
    process.exitCode = 1;
});

/**
 npx hardhat run ./scripts/node/deploy_GensisNode_on_mainnet.ts --network pijs
GenesisNode address is: 0x8d424Fa56217B671f47FBEA3384a652d0F8758b1
 */