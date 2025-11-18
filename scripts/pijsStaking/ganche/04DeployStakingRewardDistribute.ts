import { id } from "ethers/lib/utils";
import { ethers, upgrades } from "hardhat";
import {PIJSStakingRewardDistribute,Staking,ValidateNode,ValidateNodeManage} from  "../../../typechain-types";

async function main(){
    const [owner,miner,receiver] = await ethers.getSigners();
    const signer = owner.address;
    
    const args = [signer];
    const factory = await ethers.getContractFactory('PIJSStakingRewardDistribute');
    // const stakingRewardDistribute =  (await upgrades.deployProxy(factory,args,{kind:'uups'})) as PIJSStakingRewardDistribute;
    const stakingRewardDistribute = await upgrades.upgradeProxy('0x13843f3bcBeDeFEf77d6ACf63636e9c651a4ed1E', factory, { kind: 'uups' });
    await stakingRewardDistribute.deployed();
    console.log("PIJSStakingRewardDistribute address is:",stakingRewardDistribute.address);

    const tx = await stakingRewardDistribute.grantRole(stakingRewardDistribute.OPERATE_ROLE(),signer);
    await tx.wait();



}


main().catch(
    error => {
        console.log(error);
        process.exitCode = 1;
    }
);


/**
npx hardhat run ./scripts/pijsStaking/ganche/04DeployStakingRewardDistribute.ts --network ganache
PIJSStakingRewardDistribute address is: 0x13843f3bcBeDeFEf77d6ACf63636e9c651a4ed1E
 */