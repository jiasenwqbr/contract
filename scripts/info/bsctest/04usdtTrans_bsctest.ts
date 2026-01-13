import { id } from "ethers/lib/utils";
import { ethers, upgrades } from "hardhat";
import { USDTTest ,RecommendationINFO,INFONFTSellManage} from  "../../../typechain-types";
async function main(){
    const [owner,user1,user2,user3] = await ethers.getSigners();
    const usdt = await  ethers.getContractAt("USDTTest","0x640f818613eBc0534BFA62Ff189996bc2bf26003") as USDTTest;
    // const tx = await usdt.connect(owner).mint("0x80eAAC222F498242bc9aa607090b0769586C956D",ethers.utils.parseEther("10000000"));
    // await tx.wait();
    const uusdt_address = "0x43Db2F7e34F8583b2eEd39681bC77C2699f15A6d";
    const nft_address = "0xA3Cb059d4c85164cA63433b5Dd59fE986DFf85F5";
    const receiver = user1.address;
    const rootRecommender = user2.address;
    const recommandContractAddress = "0xe1fE7Ff080f842D6cb25a820FBb2db6F082fa87E";
    const nftSell_address = "0x4d25E8a0C8eAaB664aFd9186E2D4B13bc81d1A1c";
    let recommand:RecommendationINFO;
    let nftSellManage:INFONFTSellManage;
    recommand = await ethers.getContractAt("RecommendationINFO",recommandContractAddress) as RecommendationINFO;
    nftSellManage = await ethers.getContractAt("INFONFTSellManage",nftSell_address) as INFONFTSellManage;

    console.log(await recommand.getUserInfo("0x38BC81969454Bc1f5B0e52E6049E612132c53596"));


    



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
npx hardhat run ./scripts/info/bsctest/04usdtTrans_bsctest.ts --network bscTest

USDTTest address is: 0x640f818613eBc0534BFA62Ff189996bc2bf26003

 */