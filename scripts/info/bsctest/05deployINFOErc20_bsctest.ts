import { id } from "ethers/lib/utils";
import { ethers, upgrades } from "hardhat";
import { INFOErc20 } from  "../../../typechain-types";
async function main(){
    const [owner,user1,user2,user3] = await ethers.getSigners();

    const receiver = owner.address;
    const iUniswapV2Router02 = "0xD99D1c33F9fC3444f8101754aBC46c52416550D1";
    const operator = owner.address;
    const wethAddress = "0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd";
    const depositContract = "0x4d25E8a0C8eAaB664aFd9186E2D4B13bc81d1A1c"; //先用暂时的，在部署存款合约是修改

    const factory = await ethers.getContractFactory('INFOErc20');
    const erc20 = await factory.deploy(receiver,iUniswapV2Router02,operator,wethAddress,depositContract) as INFOErc20;
    await erc20.deployed();
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

INFOErc20 address is: 0x11d6ea3e3b363A9888859300EDF88533AE078e5b
infoWBNBPair address is: 0x020D128C89e7BD887949bc89D4dAD4F262fc3096
owner.address: 0x23b6AEf6Ab0ED44d137256984A3fc8DA7E9C79F9


 */