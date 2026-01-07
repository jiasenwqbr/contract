import { id } from "ethers/lib/utils";
import { ethers, upgrades } from "hardhat";
import { RecommendationINFO } from  "../../../typechain-types";
async function main(){
    const [owner,user1,user2] = await ethers.getSigners();
    const maxlength = 10000;
    const args = [maxlength];
    const factory = await ethers.getContractFactory('RecommendationINFO');
    // const recommand =  (await upgrades.deployProxy(factory,args,{kind:'uups'})) as RecommendationINFO;
    const recommand = await upgrades.upgradeProxy('0x6578AA425b21B5A533F92b88c16C1cd19167E904', factory, { kind: 'uups' });
    await recommand.deployed();
    console.log("RecommendationINFO address is:",recommand.address);
    const gensis_address = "0xb8476320D9242fDcB81fD2D634BE5207d54fb1DE";
    const tx = await recommand.setGenesisAddress(gensis_address);
    await tx.wait(2);
    console.log("genesis address is:",await recommand.getGenesisAddress());

   
   
}


main().catch(
    error => {
        console.log(error);
        process.exitCode = 1;
    }
);


/**


npx hardhat run ./scripts/info/bsc/02delpoyRecomand_bscmainnet.ts --network bscmainnetINFO
RecommendationINFO address is: 0x6578AA425b21B5A533F92b88c16C1cd19167E904
genesis address is: 0xb8476320D9242fDcB81fD2D634BE5207d54fb1DE



*/