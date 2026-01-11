import { id } from "ethers/lib/utils";
import { ethers, upgrades } from "hardhat";
import { INFOErc20 , AsiaTelevisionINFONFT,INFONFTSellManage,RecommendationINFO,USDTTest ,DepositContract,INFORewardDistribute} from  "../../../typechain-types";
async function main(){
    const [owner,user1,user2,user3] = await ethers.getSigners();

    const receiver = owner.address;
    const iUniswapV2Router02 = "0xD99D1c33F9fC3444f8101754aBC46c52416550D1";
    const operator = owner.address;
    const wethAddress = "0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd";
    const depositContract = "0x0a87de0F41E72F1D7F9A49E3827A6cbA2d581f92"; //先用暂时的，在部署存款合约是修改

    const factory = await ethers.getContractFactory('INFOErc20');
    const erc20 = await factory.deploy(receiver,iUniswapV2Router02,operator,wethAddress,depositContract) as INFOErc20;
    await erc20.deployed();
    const tx = await erc20.setTradeToPublic(true);
    await tx.wait();

    console.log("INFOErc20 address is:",erc20.address);
    
    console.log("infoWBNBPair address is:",await erc20.infoWBNBPairAddr());
   
    console.log("owner.address:",owner.address);

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
npx hardhat run ./scripts/info/bsctest/05deployINFOErc20_bsctest.ts --network bscTest

INFOErc20 address is: 0x414eC87C4c27fE1c382333b6838D571AbBd5C32c
infoWBNBPair address is: 0x9cD2884C3da4B85C94d4bF797F6CCAa3957C798E
owner.address: 0x23b6AEf6Ab0ED44d137256984A3fc8DA7E9C79F9

INFOErc20 address is: 0xC67ACDfe21cf8cefb210941f919ab1bFb3904D2b
infoWBNBPair address is: 0x500785f57727eF830f0Db70fd42620d77f4c0F22
owner.address: 0x23b6AEf6Ab0ED44d137256984A3fc8DA7E9C79F9

 */