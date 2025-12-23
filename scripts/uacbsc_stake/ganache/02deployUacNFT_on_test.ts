import { id } from "ethers/lib/utils";
import { ethers, upgrades } from "hardhat";
import { UacNFTT , StakeUACOnBsc } from  "../../../typechain-types";
async function main(){
    const [owner,user1,user2] = await ethers.getSigners();
  
    // const factory = await ethers.getContractFactory('UacNFTT');
    // const uacNft = await factory.deploy() as UacNFTT;
    // await uacNft.deployed();
    // console.log("UacNFTT address is:",uacNft.address);

    const uacNft = await ethers.getContractAt("UacNFTT","0x39c49C512178934a1DCd33176f4c85e842844EEb");

    const tx = await uacNft.batchMint(owner.address,20);
    await tx.wait();

    const tx1 = await uacNft.batchMint(user1.address,20);
    await tx1.wait();

    const tx2 = await uacNft.batchMint(user2.address,20);
    await tx2.wait();

    console.log("UacNFTT address is:",uacNft.address);


    // const uac = await ethers.getContractAt("UACBSC",uac_address) as UACBSC;
    
    // const tx1 = await uac.transfer("0x1a7844678b0e9aeb4133bcf35ae1f56b9353e481",ethers.utils.parseEther("10000000"));
    // await tx1.wait();

    //  const tx2 = await uac.transfer(owner.address,ethers.utils.parseEther("10000000"));
    // await tx2.wait();

    // console.log("0x1a7844678b0e9aeb4133bcf35ae1f56b9353e481 balance is:",await uac.balanceOf("0x1a7844678b0e9aeb4133bcf35ae1f56b9353e481"));


}


main().catch(
    error => {
        console.log(error);
        process.exitCode = 1;
    }
);




/**
npx hardhat run ./scripts/uacbsc_stake/ganache/02deployUacNFT_on_test.ts --network ganache

UacNFTT address is: 0x39c49C512178934a1DCd33176f4c85e842844EEb
 */