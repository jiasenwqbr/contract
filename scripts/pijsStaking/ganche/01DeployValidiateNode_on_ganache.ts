import { id } from "ethers/lib/utils";
import { ethers, upgrades } from "hardhat";
import {ValidateNode} from  "../../../typechain-types";

async function main(){
    const [owner,miner] = await ethers.getSigners();
    const factory = await ethers.getContractFactory('ValidateNode');
    const args = [owner.address];
    // const validateNode =  (await upgrades.deployProxy(factory,args,{kind:'uups'})) as ValidateNode;
    const validateNode = await upgrades.upgradeProxy('0xC845fD732969c90C904186b6D28960Bd935995b6', factory, { kind: 'uups' });
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
npx hardhat run ./scripts/pijsStaking/ganche/01DeployValidiateNode_on_ganache.ts --network ganache
ValidateNode address is: 0xC845fD732969c90C904186b6D28960Bd935995b6
 */