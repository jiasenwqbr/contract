import { id } from "ethers/lib/utils";
import { ethers, upgrades } from "hardhat";
import { UACBSC } from  "../../../typechain-types";
async function main(){
    const [owner,user1,user2,user3] = await ethers.getSigners();
    const factory = await ethers.getContractFactory('UACBSC');
    const uac = await factory.deploy(owner.address,ethers.utils.parseEther("1000000000")) as UACBSC;
    await uac.deployed();
    console.log("UAC address is:",uac.address);
    const tx1 = await uac.transfer(user1.address,ethers.utils.parseEther("10000"));
    await tx1.wait();

    const tx2 = await uac.transfer(user2.address,ethers.utils.parseEther("10000"));
    await tx2.wait();
     const tx3 = await uac.transfer(user3.address,ethers.utils.parseEther("10000"));
    await tx3.wait();

    console.log("owner.address:",owner.address);
    console.log("owner balance is:",await uac.balanceOf(owner.address));
    console.log("user1 balance is:",await uac.balanceOf(user1.address));
    console.log("user2 balance is:",await uac.balanceOf(user2.address));
    console.log("user3 balance is:",await uac.balanceOf(user3.address));

    // owner.address: 0x23b6AEf6Ab0ED44d137256984A3fc8DA7E9C79F9

}


main().catch(
    error => {
        console.log(error);
        process.exitCode = 1;
    }
);


/**
npx hardhat run ./scripts/uacbsc_stake/ganache/00deploy_UACBSC_testnet.ts --network ganache
UAC address is: 0x4A20C6BE6d1952c1D6529b3CdB361D426c897231
 */