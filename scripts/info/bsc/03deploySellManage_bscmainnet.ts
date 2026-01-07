import { id } from "ethers/lib/utils";
import { ethers, upgrades } from "hardhat";
import { INFONFTSellManage ,RecommendationINFO,AsiaTelevisionINFONFT} from  "../../../typechain-types";
async function main(){
    const [owner,user1,user2] = await ethers.getSigners();
    const uusdt_address = "0x55d398326f99059ff775485246999027b3197955";
    const nft_address = "0x3d3d181e392761c4EDe685754e13ab0b1dC76C4E";
    const receiver = "0x9BA72E252FA2305DEB7A864750adf893C20A52F2";
    const rootRecommender = "0xb8476320D9242fDcB81fD2D634BE5207d54fb1DE";
    const recommandContractAddress = "0x6578AA425b21B5A533F92b88c16C1cd19167E904";
    const args = [uusdt_address,nft_address,receiver,rootRecommender,recommandContractAddress];
    const factory = await ethers.getContractFactory('INFONFTSellManage');
    // const sellManage =  (await upgrades.deployProxy(factory,args,{kind:'uups'})) as INFONFTSellManage;
    const sellManage = await upgrades.upgradeProxy('0x15202E54521287F588639BF25357e258C5095BC9', factory, { kind: 'uups' });
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
    const tx1 = await nft.connect(owner).grantRole(await nft.MANAGE_ROLE(),sellManage.address);
    await tx1.wait();

    const tx2 = await sellManage.setPrice(ethers.utils.parseEther("1000"));
    await tx2.wait();
   
   
}


main().catch(
    error => {
        console.log(error);
        process.exitCode = 1;
    }
);


/**


npx hardhat run ./scripts/info/bsc/03deploySellManage_bscmainnet.ts --network bscmainnetINFO

INFONFTSellManage address is: 0x15202E54521287F588639BF25357e258C5095BC9

*/