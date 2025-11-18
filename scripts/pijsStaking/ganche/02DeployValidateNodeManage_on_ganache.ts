import { id } from "ethers/lib/utils";
import { ethers, upgrades } from "hardhat";
import {ValidateNode,ValidateNodeManage} from  "../../../typechain-types";

async function main(){
    const [owner,miner,node,receiver] = await ethers.getSigners();
    const signer = owner.address;
    const validatorContractAddress = '0xC845fD732969c90C904186b6D28960Bd935995b6';
    const  feeReceiver = receiver.address;
    const usdt = '0xb2930010444231dCA259051454b0c1D5d336112E';
    const args = [signer,validatorContractAddress,feeReceiver,usdt];
    const factory = await ethers.getContractFactory('ValidateNodeManage');
    // const validateNodeManage =  (await upgrades.deployProxy(factory,args,{kind:'uups'})) as ValidateNodeManage;
    const validateNodeManage = await upgrades.upgradeProxy('0xF1aa795e14735248EF251b3c71976AD46309cD64', factory, { kind: 'uups' });
    await validateNodeManage.deployed();
    console.log("ValidateNodeManage address is:",validateNodeManage.address);

    // role
    const validateNode = await ethers.getContractAt("ValidateNode",validatorContractAddress) as ValidateNode;
    
    const tx1 = await validateNode.grantRole(validateNode.OPERATE_ROLE(),validateNodeManage.address);
    await tx1.wait();

    console.log("validateNodeManage has OPERATE_ROLE ? ",await validateNode.hasRole(validateNode.OPERATE_ROLE(),validateNodeManage.address));

}



main().catch(
    error => {
        console.log(error);
        process.exitCode = 1;
    }
);


/**
npx hardhat run ./scripts/pijsStaking/ganche/02DeployValidateNodeManage_on_ganache.ts --network ganache
ValidateNodeManage address is: 0xF1aa795e14735248EF251b3c71976AD46309cD64
 */