import { id } from "ethers/lib/utils";
import { ethers, upgrades } from "hardhat";
import {TestUSDT} from  "../../../typechain-types";

async function main(){
    const [owner,miner,user3] = await ethers.getSigners();
    const stakingUAGFactory = await ethers.getContractFactory('TestUSDT');
    // const usdt = (
    //     await stakingUAGFactory.deploy(owner.address,miner.address)
    // ) as TestUSDT;

    const usdt = await ethers.getContractAt("TestUSDT",'0xb2930010444231dCA259051454b0c1D5d336112E');
    await usdt.deployed();
    console.log("USDT address is:",usdt.address);

    const tx = await usdt.connect(miner).mint(user3.address,ethers.utils.parseEther("1000000"));
    await tx.wait();

    console.log(await usdt.balanceOf(user3.address));


    
}

main().catch(
    error => {
        console.log(error);
        process.exitCode = 1;
    }
);


/**
npx hardhat run ./scripts/pijsStaking/ganche/00Deploy_USDT_ganche.ts --network ganache
USDT address is: 0xb2930010444231dCA259051454b0c1D5d336112E
 */
