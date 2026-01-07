import { id } from "ethers/lib/utils";
import { ethers, upgrades } from "hardhat";
import { RecommendationINFO } from  "../../../typechain-types";
async function main(){
    const [owner,user1,user2] = await ethers.getSigners();
    const maxlength = 1000;
    const args = [maxlength];
    const factory = await ethers.getContractFactory('RecommendationINFO');
    // const recommand =  (await upgrades.deployProxy(factory,args,{kind:'uups'})) as RecommendationINFO;
    const recommand = await upgrades.upgradeProxy('0xe1fE7Ff080f842D6cb25a820FBb2db6F082fa87E', factory, { kind: 'uups' });
    await recommand.deployed();
    console.log("RecommendationINFO address is:",recommand.address);

    const tx = await recommand.setGenesisAddress(user2.address);
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


npx hardhat run ./scripts/info/bsctest/02delpoyRecomand_bsctest.ts --network bscTest

RecommendationINFO address is: 0xe1fE7Ff080f842D6cb25a820FBb2db6F082fa87E
genesis address is: 0xb98E2E18259057076b3170c078F361978768d001

推荐的根地址：0xb98E2E18259057076b3170c078F361978768d001
*/