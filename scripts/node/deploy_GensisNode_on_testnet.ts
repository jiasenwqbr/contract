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
 npx hardhat run ./scripts/node/deploy_GensisNode_on_testnet.ts --network pijstestnet
GenesisNode address is: 0x95158dD21b82d8D2f62aaB88f45E5e365e1B9f27
NodeManage address is: 0x984614a7780e09465732E5B347682e291C999cBd
 */