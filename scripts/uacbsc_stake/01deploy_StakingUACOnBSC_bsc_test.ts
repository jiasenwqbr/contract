import { id } from "ethers/lib/utils";
import { ethers, upgrades } from "hardhat";
import { UACBSC , StakingUACOnBsc } from  "../../typechain-types";
async function main(){
    const [owner,user1,user2] = await ethers.getSigners();
    const uac_address = "0xedCfa509a8E8F237738B346e44e54f78c7E0e5f4";
    const args = [uac_address];
    const factory = await ethers.getContractFactory('StakingUACOnBsc');
    const stakingUACOnBsc =  (await upgrades.deployProxy(factory,args,{kind:'uups'})) as StakingUACOnBsc;
    // const stakingUACOnBsc = await upgrades.upgradeProxy('0x145d54E0BE098acfBb9EBdbC83C72e5e897f7d64', factory, { kind: 'uups' });
    await stakingUACOnBsc.deployed();
    console.log("StakingUACOnBsc address is:",stakingUACOnBsc.address);
    const uac = await ethers.getContractAt("UACBSC",uac_address) as UACBSC;
    
    const tx1 = await uac.transfer("0x1a7844678b0e9aeb4133bcf35ae1f56b9353e481",ethers.utils.parseEther("10000000"));
    await tx1.wait();

    console.log("0x1a7844678b0e9aeb4133bcf35ae1f56b9353e481 balance is:",await uac.balanceOf("0x1a7844678b0e9aeb4133bcf35ae1f56b9353e481"));


}


main().catch(
    error => {
        console.log(error);
        process.exitCode = 1;
    }
);


/**


npx hardhat run ./scripts/uacbsc_stake/01deploy_StakingUACOnBSC_bsc_test.ts --network bscTest

StakingUACOnBsc address is: 0x19B75A03dAFb6D6819e86F970d4e3354F02a3216

*/