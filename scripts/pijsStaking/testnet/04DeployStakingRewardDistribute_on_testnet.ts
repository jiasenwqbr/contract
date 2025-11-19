import { id } from "ethers/lib/utils";
import { ethers, upgrades } from "hardhat";
import {PIJSStakingRewardDistribute,Staking,ValidateNode,ValidateNodeManage} from  "../../../typechain-types";

async function main(){
    const [owner,miner,receiver] = await ethers.getSigners();
    
    const signer = "0xd4f0f0c79a35f217e5de4bff0752ba63cbc013e9";
    
    const args = [signer];
    const factory = await ethers.getContractFactory('PIJSStakingRewardDistribute');
    const stakingRewardDistribute =  (await upgrades.deployProxy(factory,args,{kind:'uups'})) as PIJSStakingRewardDistribute;
    // const stakingRewardDistribute = await upgrades.upgradeProxy('0x0202361152f9F8c9c40CeB7b6B80E1384f648bDE', factory, { kind: 'uups' });
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
npx hardhat run ./scripts/pijsStaking/testnet/04DeployStakingRewardDistribute_on_testnet.ts --network pijstestnet
PIJSStakingRewardDistribute address is: 0x0202361152f9F8c9c40CeB7b6B80E1384f648bDE
 */