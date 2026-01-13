import { id } from "ethers/lib/utils";
import { ethers, upgrades } from "hardhat";
import { INFONFTSellManage ,RecommendationINFO,AsiaTelevisionINFONFT} from  "../../../typechain-types";
async function main(){
    const [owner,user1,user2] = await ethers.getSigners();
    const uusdt_address = "0x43Db2F7e34F8583b2eEd39681bC77C2699f15A6d";
    const nft_address = "0xA3Cb059d4c85164cA63433b5Dd59fE986DFf85F5";
    const receiver = user1.address;
    const rootRecommender = user2.address;
    const recommandContractAddress = "0xe1fE7Ff080f842D6cb25a820FBb2db6F082fa87E";
    const args = [uusdt_address,nft_address,receiver,rootRecommender,recommandContractAddress];
    const factory = await ethers.getContractFactory('INFONFTSellManage');
    // const sellManage =  (await upgrades.deployProxy(factory,args,{kind:'uups'})) as INFONFTSellManage;
    const sellManage = await upgrades.upgradeProxy('0x4d25E8a0C8eAaB664aFd9186E2D4B13bc81d1A1c', factory, { kind: 'uups' });
    await sellManage.deployed();
    console.log("INFONFTSellManage address is:",sellManage.address);
    // // const tx1 = await stakingUACOnBsc.setNftAddress(nft_address);
    // // await tx1.wait();
    // const recommand = await ethers.getContractAt("RecommendationINFO",recommandContractAddress) as RecommendationINFO;
    // const tx = await recommand.grantRole(await recommand.OPERATE_ROLE(),sellManage.address);
    // {
    //      gasLimit:12000000
    // }
    // await tx.wait();
    const nft = await ethers.getContractAt("AsiaTelevisionINFONFT",nft_address) as AsiaTelevisionINFONFT;
    const tx1 = await nft.grantRole(await nft.MANAGE_ROLE(),sellManage.address);
    await tx1.wait();

    const tx2 = await sellManage.setPrice(ethers.utils.parseEther("1000"));
    await tx2.wait();

    // set para
    const tx3 = await sellManage.setParam(
        uusdt_address,
        nft_address,
        receiver,
        rootRecommender,
        recommandContractAddress
    );
    await tx3.wait();
   
   
}


main().catch(
    error => {
        console.log(error);
        process.exitCode = 1;
    }
);


/**


npx hardhat run ./scripts/info/bsctest/03deploySellManage_bsctest.ts --network bscTest

INFONFTSellManage address is: 0x4d25E8a0C8eAaB664aFd9186E2D4B13bc81d1A1c

*/