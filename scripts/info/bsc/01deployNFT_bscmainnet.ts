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
npx hardhat run ./scripts/info/bsc/01deployNFT_bscmainnet.ts --network bscmainnetINFO
AsiaTelevisionINFONFT address is: 0x3d3d181e392761c4EDe685754e13ab0b1dC76C4E
owner.address: 0x7ae1AE9F7Fc8656144302C415D750fcB947E98d7
 */