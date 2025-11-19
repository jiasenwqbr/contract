import { id } from "ethers/lib/utils";
import { ethers, upgrades } from "hardhat";
import {Staking,ValidateNode,ValidateNodeManage} from  "../../../typechain-types";

async function main(){
    const [owner,miner,receiver] = await ethers.getSigners();
    const signer = "0xd4f0f0c79a35f217e5de4bff0752ba63cbc013e9";
    const validatorContractAddress = '0xaf28eE5059523bC746c9eE2A463B6a3171689Fd8';

    const args = [signer,validatorContractAddress];
    const factory = await ethers.getContractFactory('Staking');
    const staking =  (await upgrades.deployProxy(factory,args,{kind:'uups'})) as Staking;
    // const staking = await upgrades.upgradeProxy('0xAb71f42D296DbbdCc4D06AA2250173469e6AFFeD', factory, { kind: 'uups' });
    await staking.deployed();
    console.log("Staking address is:",staking.address);

    // role
    const validateNode = await ethers.getContractAt("ValidateNode",validatorContractAddress) as ValidateNode;
    
    const tx1 = await validateNode.grantRole(validateNode.OPERATE_ROLE(),staking.address);
    await tx1.wait();

    console.log("staking has OPERATE_ROLE ? ",await validateNode.hasRole(validateNode.OPERATE_ROLE(),staking.address));
}


main().catch(
    error => {
        console.log(error);
        process.exitCode = 1;
    }
);


/**
 
npx hardhat run ./scripts/pijsStaking/testnet/03DeployStaking_on_testnet.ts --network pijstestnet
Staking address is: 0xAb71f42D296DbbdCc4D06AA2250173469e6AFFeD

 */