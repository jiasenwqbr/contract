import { id } from "ethers/lib/utils";
import { ethers, upgrades } from "hardhat";
import { AsiaTelevisionINFONFT } from  "../../../typechain-types";
async function main(){
    const [owner,user1,user2,user3] = await ethers.getSigners();
    const factory = await ethers.getContractFactory('AsiaTelevisionINFONFT');
    const nft = await factory.deploy() as AsiaTelevisionINFONFT;
    await nft.deployed();
    console.log("AsiaTelevisionINFONFT address is:",nft.address);
   
    console.log("owner.address:",owner.address);

}


main().catch(
    error => {
        console.log(error);
        process.exitCode = 1;
    }
);


/**
 * 
 * 
npx hardhat run ./scripts/info/ganache/01deployNFT_ganache.ts --network ganache

AsiaTelevisionINFONFT address is: 0x9D36918d5313A8156108c14dFaAB496Ab1d4DF10
owner.address: 0x51b448CA6644f7c472D3c0D8BEe2e7119e698d39

 */