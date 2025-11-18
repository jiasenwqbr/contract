import { id } from "ethers/lib/utils";
import { ethers, upgrades } from "hardhat";
import {Staking,ValidateNode,ValidateNodeManage} from  "../../../typechain-types";

async function main(){
    const [owner,miner,receiver] = await ethers.getSigners();
    const signer = owner.address;
    const validatorContractAddress = '0xC845fD732969c90C904186b6D28960Bd935995b6';

    const args = [signer,validatorContractAddress];
    const factory = await ethers.getContractFactory('Staking');
    // const staking =  (await upgrades.deployProxy(factory,args,{kind:'uups'})) as Staking;
    const staking = await upgrades.upgradeProxy('0xF800c7aD3a92f64455B8838BDe2a173FEE95946e', factory, { kind: 'uups' });
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
 
npx hardhat run ./scripts/pijsStaking/ganche/03DeployStaking_on_ganache.ts --network ganache
Staking address is: 0xF800c7aD3a92f64455B8838BDe2a173FEE95946e

 */