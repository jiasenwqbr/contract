import { id } from "ethers/lib/utils";
import { ethers, upgrades } from "hardhat";
import { UACBSC , StakeUACOnBscUpgradeble } from  "../../../typechain-types";
async function main(){
    const [owner,user1,user2] = await ethers.getSigners();
    const uac_address = "0x4A20C6BE6d1952c1D6529b3CdB361D426c897231";
    const nft_address = "0x39c49C512178934a1DCd33176f4c85e842844EEb";
    const args = [uac_address,nft_address];
    const factory = await ethers.getContractFactory('StakeUACOnBscUpgradeble');
    // const stakingUACOnBsc =  (await upgrades.deployProxy(factory,args,{kind:'uups'})) as StakeUACOnBscUpgradeble;
    const stakingUACOnBsc = await upgrades.upgradeProxy('0x6FF6FE6964AF2de6ED7D3cFBEb394981c34e60b0', factory, { kind: 'uups' });
    await stakingUACOnBsc.deployed();
    console.log("StakeUACOnBscUpgradeble address is:",stakingUACOnBsc.address);
     const uac = await ethers.getContractAt("UACBSC",uac_address);
    const tx = await uac.mint(stakingUACOnBsc.address,ethers.utils.parseEther("1000000"));
    await tx.wait();

    console.log(
    "stake usc balance",
    await uac.balanceOf(stakingUACOnBsc.address)
    );
}


main().catch(
    error => {
        console.log(error);
        process.exitCode = 1;
    }
);


/**


npx hardhat run ./scripts/uacbsc_stake/ganache/03deploy_StakeUACOnBscUpgradeble_testnet.ts --network ganache

StakeUACOnBscUpgradeble address is: 0x6FF6FE6964AF2de6ED7D3cFBEb394981c34e60b0

*/