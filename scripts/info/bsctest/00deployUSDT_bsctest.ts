import { id } from "ethers/lib/utils";
import { ethers, upgrades } from "hardhat";
import { USDTTest } from  "../../../typechain-types";
async function main(){
    const [owner,user1,user2,user3] = await ethers.getSigners();
    const factory = await ethers.getContractFactory('USDTTest');
    // const usdt = await factory.deploy(owner.address,ethers.utils.parseEther("1000000000")) as USDTTest;
    // await usdt.deployed();

    const usdt = await ethers.getContractAt("USDTTest","0x75A79414fcae320Ac6B063430239654b1a23A7Dd");
    console.log("USDTTest address is:",usdt.address);
   
    console.log("owner.address:",owner.address);

    // 0x693Dd8b5AA932F3b80aF7B797C6877086eb08a35
    const tx1 = await usdt.mint("0x693Dd8b5AA932F3b80aF7B797C6877086eb08a35",ethers.utils.parseEther("100000"));
    await tx1.wait();

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



USDTTest address is: 0x75A79414fcae320Ac6B063430239654b1a23A7Dd

owner.address: 0x23b6AEf6Ab0ED44d137256984A3fc8DA7E9C79F9

 */