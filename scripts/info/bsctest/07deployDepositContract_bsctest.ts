import { id } from "ethers/lib/utils";
import { ethers, upgrades } from "hardhat";
import { INFONFTSellManage ,INFOErc20,DepositContract,IUniswapV2Router02,IUniswapV2Factory} from  "../../../typechain-types";

async function main(){
    const [owner,user1,user2,user3] = await ethers.getSigners();
    const uusdt_address = "0x75A79414fcae320Ac6B063430239654b1a23A7Dd";
    const infoAddress = "0xC67ACDfe21cf8cefb210941f919ab1bFb3904D2b";
    const swapRouterAddress = "0xD99D1c33F9fC3444f8101754aBC46c52416550D1";
    const recommandAddress = "0xe1fE7Ff080f842D6cb25a820FBb2db6F082fa87E";
    const depositAllocation = [
        "0x1375E91522Cbc110d6844c1187610869373D9ca4",
        "0xc36268C3Fe6d574A329Ec0676031b6dFe407a7e2",
        "0x6eE5B70cf3652678134e6609C98892FDBA2262Dc",
        "0x3fB59162Cd615A1ab4DC8163cC7aC3e1Dd97cA10"];
    const depositAllocationRatio = [500,350,100,50];
    const lpReceiveAddress = user3.address;

    // deploy
    const args = [uusdt_address,infoAddress,swapRouterAddress,depositAllocation,depositAllocationRatio];
    const factory = await ethers.getContractFactory('DepositContract');
    // const depositContract =  (await upgrades.deployProxy(factory,args,{kind:'uups'})) as DepositContract;
    const depositContract = await upgrades.upgradeProxy('0x806Fd9c7e906F97627559f3F789fFE9B0b4e61a6', factory, { kind: 'uups' });
    await depositContract.deployed();
    console.log("DepositContract address is:",depositContract.address);

    // set INFO_ROLE
    const tx1 = await depositContract.grantRole(await depositContract.INFO_ROLE(),infoAddress);
    await tx1.wait();

    const tx11 = await depositContract.setPara( uusdt_address,infoAddress,swapRouterAddress,recommandAddress,lpReceiveAddress);
    await tx11.wait();

    // // set INFOErc20 contract 
    const infoErc20 = await ethers.getContractAt("INFOErc20",infoAddress);
    const tx = await infoErc20.setDepositContract(depositContract.address);
    await tx.wait();

    // set INFOErc20 fee receiver
   const tx2 = await infoErc20.setBuyFeeReceivers([
    user1.address,depositContract.address,user2.address,user2.address
   ],[
    20,160,10,10
   ]);
   await tx2.wait();

   const tx3 = await infoErc20.setSellFeeReceivers([
    user1.address,depositContract.address,user2.address,user2.address
   ],[
    20,160,10,10
   ]);
   await tx3.wait();

   // set INFO globleWiteList
   const tx4 = await infoErc20.updateGlobalWhitelist(swapRouterAddress,true);
   await tx.wait();
   const swapRouter = await ethers.getContractAt("IUniswapV2Router02",swapRouterAddress) as IUniswapV2Router02;
    const factoryAddress = await swapRouter.factory();
    console.log("factory address:",factoryAddress);
    const factory1 = await ethers.getContractAt("IUniswapV2Factory",factoryAddress) as IUniswapV2Factory;
    const wbnb = await swapRouter.WETH();
    console.log("wbnb address:",wbnb);
   const info_bnb_PairAddress = await factory1.getPair(infoAddress,wbnb);

   const tx5 = await infoErc20.updateGlobalWhitelist(info_bnb_PairAddress,true);
   await tx5.wait();

   

    

}


main().catch(
    error => {
        console.log(error);
        process.exitCode = 1;
    }
);


/**


npx hardhat run ./scripts/info/bsctest/07deployDepositContract_bsctest.ts --network bscTest

DepositContract address is: 0x28EE3F1F088dB35B26024364B485063FdF7a7cE8


user1: 0x600A06CF3A0152cbd4b1b090432b3220653bD972
user2: 0xb98E2E18259057076b3170c078F361978768d001
user3: 0x3D57d0344a0e89566e336203B86A99B5371b4918
///////////////////////////////////////////////////////////

INFOErc20 address is: 0xC67ACDfe21cf8cefb210941f919ab1bFb3904D2b
DepositContract address is: 0x806Fd9c7e906F97627559f3F789fFE9B0b4e61a6
factory address: 0x6725F303b657a9451d8BA641348b6761A6CC7a17
wbnb address: 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd


*/