import { id } from "ethers/lib/utils";
import { ethers, upgrades } from "hardhat";
import {LPLocker} from  "../../typechain-types";

async function main(){
    const [owner] = await ethers.getSigners();
    const factory = await ethers.getContractFactory("LPLocker");
    const simpleLPLocker = await factory.deploy();
    await simpleLPLocker.deployed();
    

    // const simpleLPLocker = await ethers.getContractAt("SimpleLPLocker","0x23b6AEf6Ab0ED44d137256984A3fc8DA7E9C79F9") as LPLocker;
    console.log("LPLocker address is:",simpleLPLocker.address);

    const tx = await simpleLPLocker.transferOwnership('0xAD279F4b4c319002fa2f801D140974F1EF9a0d3f');
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
npx hardhat run ./scripts/test/deploySimpleLPLocker_on_testnet.ts --network pijs

 */