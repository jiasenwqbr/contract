import { id } from "ethers/lib/utils";
import { ethers, upgrades } from "hardhat";
import { UACBSC } from  "../../typechain-types";
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


    console.log("owner balance is:",await uac.balanceOf(owner.address));
    console.log("user1 balance is:",await uac.balanceOf(user1.address));
    console.log("user2 balance is:",await uac.balanceOf(user2.address));
    console.log("user3 balance is:",await uac.balanceOf(user3.address));

}


main().catch(
    error => {
        console.log(error);
        process.exitCode = 1;
    }
);


/**
npx hardhat run ./scripts/uacbsc_stake/00deploy_UACBSC_testnet.ts --network ganache

UAC address is: 0x710263567fD99E62c3D95772D4870b0948089191
 */