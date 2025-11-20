import { id } from "ethers/lib/utils";
import { ethers, upgrades } from "hardhat";
import {SimpleLPLocker} from  "../../typechain-types";

async function main(){
    const [owner] = await ethers.getSigners();
    // const factory = await ethers.getContractFactory("SimpleLPLocker");
    // const simpleLPLocker = await factory.deploy();
    // await simpleLPLocker.deployed();
    

    const simpleLPLocker = await ethers.getContractAt("SimpleLPLocker","0xF40Fafd386a83072C226DF9F76D097d2cEA8553a") as SimpleLPLocker;
    console.log("SimpleLPLocker address is:",simpleLPLocker.address);

    const tx = await simpleLPLocker.transferOwnership("0x1094Aba5c89f650e8d14A6A6E67eA22CADD9FB22");
    await tx.wait();
    console.log("owner is : ",await simpleLPLocker.owner());

}


main().catch(
    error => {
        console.log(error);
        process.exitCode = 1;
    }
);

/**
npx hardhat run ./scripts/test/deploySimpleLPLocker_on_testnet.ts --network pijstestnet

 */