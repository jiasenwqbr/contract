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
npx hardhat run ./scripts/info/bsctest/01deployNFT_bsctest.ts --network bscTest

AsiaTelevisionINFONFT address is: 0xA3Cb059d4c85164cA63433b5Dd59fE986DFf85F5

 */