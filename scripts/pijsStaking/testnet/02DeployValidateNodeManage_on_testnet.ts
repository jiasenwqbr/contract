import { id } from "ethers/lib/utils";
import { ethers, upgrades } from "hardhat";
import {ValidateNode,ValidateNodeManage} from  "../../../typechain-types";

async function main(){
    const [owner,miner,node,receiver] = await ethers.getSigners();
    const signer = "0xd4f0f0c79a35f217e5de4bff0752ba63cbc013e9";
    const validatorContractAddress = '0xaf28eE5059523bC746c9eE2A463B6a3171689Fd8';
    const  feeReceiver = receiver.address;
    const usdt = '0x3F00C9dd4F081D7b6b758555c621FbEb09d519FD';
    const args = [signer,validatorContractAddress,feeReceiver,usdt];
    const factory = await ethers.getContractFactory('ValidateNodeManage');
    // const validateNodeManage =  (await upgrades.deployProxy(factory,args,{kind:'uups'})) as ValidateNodeManage;
    const validateNodeManage = await upgrades.upgradeProxy('0xd61c57aCdD70561d908c492ef99884f4F1b03319', factory, { kind: 'uups' });
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
npx hardhat run ./scripts/pijsStaking/testnet/02DeployValidateNodeManage_on_testnet.ts --network pijstestnet
ValidateNodeManage address is: 0xd61c57aCdD70561d908c492ef99884f4F1b03319
 */