import { id } from "ethers/lib/utils";
import { ethers, upgrades } from "hardhat";
import { UACBSC } from  "../../../typechain-types";
async function main(){
    const [owner,user1,user2,user3] = await ethers.getSigners();
    // const factory = await ethers.getContractFactory('UACBSC');
    // const uac = await factory.deploy(owner.address,ethers.utils.parseEther("1000000000")) as UACBSC;
    // await uac.deployed();
    // console.log("UAC address is:",uac.address);
    // const tx1 = await uac.transfer(user1.address,ethers.utils.parseEther("10000"));
    // await tx1.wait();

    // const tx2 = await uac.transfer(user2.address,ethers.utils.parseEther("10000"));
    // await tx2.wait();
    //  const tx3 = await uac.transfer(user3.address,ethers.utils.parseEther("10000"));
    // await tx3.wait();

    console.log("owner.address:",owner.address);
    //console.log("owner balance is:",await uac.balanceOf(owner.address));

    // 0x80aB92fec22216c07bBfB0421C2AB684dd0B969E


    const uac = await ethers.getContractAt("UACBSC","0x62f59D17B395B4437Cc4C673d075b898D2d95eAe");
    console.log("before transfer:",ethers.utils.formatEther( await uac.balanceOf(owner.address)));

    const tx1 = await uac.connect(owner).transfer("0x80aB92fec22216c07bBfB0421C2AB684dd0B969E",ethers.utils.parseEther("957729202.9657661784548841"));
    await tx1.wait(3);
    console.log("after transfer:",ethers.utils.formatEther( await uac.balanceOf(owner.address)));

    

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
 npx hardhat run ./scripts/uacbsc_stake/mainnet/00deploy_UACBSC_bsc-mainnet.ts --network bscmainnet

 UAC address is: 0x62f59D17B395B4437Cc4C673d075b898D2d95eAe
owner.address: 0xC7794f25c88D74521A370DF6D7E10175ebb2010a
owner balance is: BigNumber { value: "1000000000000000000000000000" }
BigNumber { value: "1000000000000000000000000000" }
 */