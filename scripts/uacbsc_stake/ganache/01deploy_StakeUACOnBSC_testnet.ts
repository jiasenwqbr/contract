import { id } from "ethers/lib/utils";
import { ethers, upgrades } from "hardhat";
import { UacNFTT , StakeUACOnBsc ,UACBSC} from  "../../../typechain-types";
async function main(){
    const [owner,user1,user2] = await ethers.getSigners();
    const uac_address = "0x4A20C6BE6d1952c1D6529b3CdB361D426c897231";
    const nft_address = "0x39c49C512178934a1DCd33176f4c85e842844EEb";
    const factory = await ethers.getContractFactory('StakeUACOnBsc');
    const stake = await factory.deploy(uac_address,nft_address) as StakeUACOnBsc;
    await stake.deployed();
    console.log("StakeUACOnBsc address is:",stake.address);

    const uac = await ethers.getContractAt("UACBSC",uac_address);
    const tx = await uac.mint(stake.address,ethers.utils.parseEther("1000000"));
    await tx.wait();

    console.log(
  "stake usc balance",
  await uac.balanceOf(stake.address)
);
}


main().catch(
    error => {
        console.log(error);
        process.exitCode = 1;
    }
);


/**

npx hardhat run ./scripts/uacbsc_stake/ganache/01deploy_StakeUACOnBSC_testnet.ts --network ganache

StakeUACOnBsc address is: 0xF6C517DF90FC4b94Ce6fC36BA4d099A233630B89



*/