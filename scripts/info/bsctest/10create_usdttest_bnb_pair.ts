import { id } from "ethers/lib/utils";
import { ethers, upgrades } from "hardhat";
import { INFOErc20,DepositContract,INFORewardDistribute,IUniswapV2Router02,IUniswapV2Factory,USDTTest,IUniswapV2Pair} from  "../../../typechain-types";

async function main(){
     const [owner,user1,user2] = await ethers.getSigners();
    const infoerc20_address = "0x11d6ea3e3b363A9888859300EDF88533AE078e5b";
    const usdt_test_address = "0x640f818613eBc0534BFA62Ff189996bc2bf26003";
    const swapRouterAddress = "0xD99D1c33F9fC3444f8101754aBC46c52416550D1";



    // 创建usdt、wbnb交易对
    const swapRouter = await ethers.getContractAt("IUniswapV2Router02",swapRouterAddress) as IUniswapV2Router02;
    const factoryAddress = await swapRouter.factory();
    console.log("factory address:",factoryAddress);
    const factory = await ethers.getContractAt("IUniswapV2Factory",factoryAddress) as IUniswapV2Factory;
    const wbnb = await swapRouter.WETH();
    console.log("wbnb address:",wbnb);
    // const tx = await factory.createPair(usdt_test_address,wbnb);
    // await tx.wait();
    const pair = await factory.getPair(usdt_test_address,wbnb);
    console.log("usdt/wbnb pair address:",pair);

    const ownerBNBbalance =  await ethers.provider.getBalance(owner.address);
    console.log("owner bnb balance :",ethers.utils.formatEther(ownerBNBbalance));

    const usdt = await ethers.getContractAt("USDTTest",usdt_test_address);
    console.log("owner usdt balance :",ethers.utils.formatEther(await usdt.balanceOf(owner.address)));

    const deadline = Math.floor(Date.now() / 1000) + 60 * 10; // 10分钟
    // 添加流动性
    // const tx21 = await usdt.connect(owner).approve(swapRouterAddress,ethers.utils.parseEther("100"));
    // await tx21.wait();
    
    // const allowance = await usdt.allowance(owner.address, swapRouterAddress);
    // const tx = await swapRouter.connect(owner).addLiquidityETH(
    //     usdt_test_address,
    //     ethers.utils.parseEther("10"),
    //     0, // 代币最小接收量（滑点保护）
    //     0, // ETH最小接收量
    //     owner.address,
    //     deadline,
    //     {
    //         value: ethers.utils.parseEther("0.1") ,
    //         gasLimit: 300000  // 手动设置Gas Limit
    //     }
    // );
    // const reciept = await tx.wait();
    // // console.log("reciept:",reciept);
    // console.log("Liquidity added.");

    const usdt_bnb_Pair = await ethers.getContractAt("IUniswapV2Pair",pair);
    const reserves = await usdt_bnb_Pair.getReserves();
    console.log("Reserves:", ethers.utils.formatEther(reserves[0].toString()), ethers.utils.formatEther(reserves[1].toString()));
    const lpBalance = ethers.utils.formatEther(await usdt_bnb_Pair.balanceOf(owner.address));
    console.log("lpBalance:", lpBalance);


}
main().catch(
    error => {
        console.log(error);
        process.exitCode = 1;
    }
);


/**
npx hardhat run ./scripts/info/bsctest/10create_usdttest_bnb_pair.ts --network bscTest

factory address: 0x6725F303b657a9451d8BA641348b6761A6CC7a17
wbnb address: 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd
usdt/wbnb pair address: 0x4dCa7367AAc18865A95545ebD84703C91A6d1609




 */