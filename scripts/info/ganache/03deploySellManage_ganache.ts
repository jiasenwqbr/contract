import { id } from "ethers/lib/utils";
import { ethers, upgrades } from "hardhat";
import { INFONFTSellManage ,RecommendationINFO,AsiaTelevisionINFONFT} from  "../../../typechain-types";
async function main(){
    const [owner,user1,user2] = await ethers.getSigners();
    const uusdt_address = "0xD8703021d43420c19Ba393501574B2250732060d";
    const nft_address = "0x9D36918d5313A8156108c14dFaAB496Ab1d4DF10";
    const receiver = user1.address;
    const rootRecommender = user2.address;
    const recommandContractAddress = "0x976d1123294D237c1dD0E5E62B968F447E90e6Ce";
    const args = [uusdt_address,nft_address,receiver,rootRecommender,recommandContractAddress];
    const factory = await ethers.getContractFactory('INFONFTSellManage');
    // const sellManage =  (await upgrades.deployProxy(factory,args,{kind:'uups'})) as INFONFTSellManage;
    const sellManage = await upgrades.upgradeProxy('0xb4502B3F2d65Ec512297B2c9A992A47DF0410F4d', factory, { kind: 'uups' });
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

    const tx2 = await sellManage.setPrice(ethers.utils.formatEther("1000"));
    await tx2.wait();

   
   
}


main().catch(
    error => {
        console.log(error);
        process.exitCode = 1;
    }
);


/**


npx hardhat run ./scripts/info/ganache/03deploySellManage_ganache.ts --network ganache

INFONFTSellManage address is: 0xb4502B3F2d65Ec512297B2c9A992A47DF0410F4d

*/