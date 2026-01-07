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
npx hardhat run ./scripts/info/bsctest/00deployUSDT_bsctest.ts --network bscTest

USDTTest address is: 0x640f818613eBc0534BFA62Ff189996bc2bf26003

 */