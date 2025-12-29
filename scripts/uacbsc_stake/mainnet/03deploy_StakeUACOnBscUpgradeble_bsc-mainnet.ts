import { id } from "ethers/lib/utils";
import { ethers, upgrades } from "hardhat";
import { UACBSC , StakeUACOnBscUpgradeble } from  "../../../typechain-types";
async function main(){
    const [owner,user1,user2] = await ethers.getSigners();
    const uac_address = "0x62f59D17B395B4437Cc4C673d075b898D2d95eAe";
    const nft_address = "0xa21c8a2fd49eb7e008b452f1b2573bbff0ea97fd";
    const args = [uac_address,nft_address];
    const factory = await ethers.getContractFactory('StakeUACOnBscUpgradeble');
    // const stakingUACOnBsc =  (await upgrades.deployProxy(factory,args,{kind:'uups'})) as StakeUACOnBscUpgradeble;
    const stakingUACOnBsc = await upgrades.upgradeProxy('0xA8b329BfAbEC58346F7a3aC5Fb23689919131b8F', factory, { kind: 'uups' });
    await stakingUACOnBsc.deployed();
    console.log("StakeUACOnBscUpgradeble address is:",stakingUACOnBsc.address);
    // const tx1 = await stakingUACOnBsc.setNftAddress(nft_address);
    // await tx1.wait();

    console.log(await stakingUACOnBsc.getNftAddress());
   
}


main().catch(
    error => {
        console.log(error);
        process.exitCode = 1;
    }
);


/**


npx hardhat run ./scripts/uacbsc_stake/mainnet/03deploy_StakeUACOnBscUpgradeble_bsc-mainnet.ts --network bscmainnet

StakeUACOnBscUpgradeble address is: 0xA8b329BfAbEC58346F7a3aC5Fb23689919131b8F

*/