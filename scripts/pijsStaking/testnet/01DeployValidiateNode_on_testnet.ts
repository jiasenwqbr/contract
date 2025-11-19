import { id } from "ethers/lib/utils";
import { ethers, upgrades } from "hardhat";
import {ValidateNode} from  "../../../typechain-types";

async function main(){
    const [owner,miner] = await ethers.getSigners();
    const factory = await ethers.getContractFactory('ValidateNode');
    const args = [owner.address];
    // const validateNode =  (await upgrades.deployProxy(factory,args,{kind:'uups'})) as ValidateNode;
    const validateNode = await upgrades.upgradeProxy('0xaf28eE5059523bC746c9eE2A463B6a3171689Fd8', factory, { kind: 'uups' });
    await validateNode.deployed();
    console.log("ValidateNode address is:",validateNode.address);

}


main().catch(
    error => {
        console.log(error);
        process.exitCode = 1;
    }
);


/**
npx hardhat run ./scripts/pijsStaking/testnet/01DeployValidiateNode_on_testnet.ts --network pijstestnet
ValidateNode address is: 0xaf28eE5059523bC746c9eE2A463B6a3171689Fd8
 */