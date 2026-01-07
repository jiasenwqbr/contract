import { id } from "ethers/lib/utils";
import { ethers, upgrades } from "hardhat";
import { USDTTest } from  "../../../typechain-types";
async function main(){
    const [owner,user1,user2,user3] = await ethers.getSigners();
    const factory = await ethers.getContractFactory('USDTTest');
    const usdt = await factory.deploy(owner.address,ethers.utils.parseEther("1000000000")) as USDTTest;
    await usdt.deployed();
    console.log("USDTTest address is:",usdt.address);
   
    console.log("owner.address:",owner.address);

}


main().catch(
    error => {
        console.log(error);
        process.exitCode = 1;
    }
);


/**
 * 
 * 
npx hardhat run ./scripts/info/ganache/00deployUSDT_ganache.ts --network ganache

USDTTest address is: 0xD8703021d43420c19Ba393501574B2250732060d
owner.address: 0x51b448CA6644f7c472D3c0D8BEe2e7119e698d39

 */