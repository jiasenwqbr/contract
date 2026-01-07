import { id } from "ethers/lib/utils";
import { ethers, upgrades } from "hardhat";
import { RecommendationINFO } from  "../../../typechain-types";
async function main(){
    const [owner,user1,user2] = await ethers.getSigners();
    const maxlength = 1000;
    const args = [maxlength];
    const factory = await ethers.getContractFactory('RecommendationINFO');
    // const recommand =  (await upgrades.deployProxy(factory,args,{kind:'uups'})) as RecommendationINFO;
    const recommand = await upgrades.upgradeProxy('0x976d1123294D237c1dD0E5E62B968F447E90e6Ce', factory, { kind: 'uups' });
    await recommand.deployed();
    console.log("RecommendationINFO address is:",recommand.address);
    
    const tx = await recommand.setGenesisAddress(user2.address);
    await tx.wait();
    console.log("genesis address is:",await recommand.getGenesisAddress());

   
   
}


main().catch(
    error => {
        console.log(error);
        process.exitCode = 1;
    }
);


/**


npx hardhat run ./scripts/info/ganache/02delpoyRecomand_ganache.ts --network ganache

RecommendationINFO address is: 0x976d1123294D237c1dD0E5E62B968F447E90e6Ce

*/