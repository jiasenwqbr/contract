import { id } from "ethers/lib/utils";
import { ethers, upgrades } from "hardhat";
import { UACBSC , StakingUACOnBsc } from  "../../typechain-types";
async function main(){
    const [owner,user1,user2] = await ethers.getSigners();
    const uac_address = "0x710263567fD99E62c3D95772D4870b0948089191";
    const args = [uac_address];
    const factory = await ethers.getContractFactory('StakingUACOnBsc');
    // const stakingUACOnBsc =  (await upgrades.deployProxy(factory,args,{kind:'uups'})) as StakingUACOnBsc;
    const stakingUACOnBsc = await upgrades.upgradeProxy('0x145d54E0BE098acfBb9EBdbC83C72e5e897f7d64', factory, { kind: 'uups' });
    await stakingUACOnBsc.deployed();
    console.log("StakingUACOnBsc address is:",stakingUACOnBsc.address);
    const uac = await ethers.getContractAt("UACBSC",uac_address) as UACBSC;
    
    // const tx1 = await uac.transfer(stakingUACOnBsc.address,ethers.utils.parseEther("10000000"));
    // await tx1.wait();

    console.log("StakingUACOnBsc balance is:",await uac.balanceOf(stakingUACOnBsc.address));


}


main().catch(
    error => {
        console.log(error);
        process.exitCode = 1;
    }
);


/**
npx hardhat run ./scripts/uacbsc_stake/01deploy_StakingUACOnBSC_testnet.ts --network ganache

StakingUACOnBsc address is: 0x145d54E0BE098acfBb9EBdbC83C72e5e897f7d64

*/