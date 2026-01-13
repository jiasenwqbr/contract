import { id } from "ethers/lib/utils";
import { ethers, upgrades } from "hardhat";
import { INFOErc20,DepositContract,INFORewardDistribute,IUniswapV2Router02,IUniswapV2Factory,USDTTest,IUniswapV2Pair} from  "../../../typechain-types";

async function main(){
    const [owner,user1,user2] = await ethers.getSigners();
    const infoerc20_address = "0x1B9D597997DC0BC1b41786556a48C976866B5B64";
    const usdt_test_address = "0x43Db2F7e34F8583b2eEd39681bC77C2699f15A6d";
    const swapRouterAddress = "0xD99D1c33F9fC3444f8101754aBC46c52416550D1";
    const depositC = "0xc4f7F567838918610D4481cF875495Da241A352c";

    const swapRouter = await ethers.getContractAt("IUniswapV2Router02",swapRouterAddress) as IUniswapV2Router02;
    const factoryAddress = await swapRouter.factory();
    console.log("factory address:",factoryAddress);
       
    const factory = await ethers.getContractAt("IUniswapV2Factory",factoryAddress) as IUniswapV2Factory;
    const wbnb = await swapRouter.WETH();

    // const tx11 = await factory.createPair(usdt_test_address,wbnb);
    // await tx11.wait(2);

    console.log("wbnb address:",wbnb);
    console.log("#########    usdt/wbnb     #########");
    const usdt_bnb_pair_address = await factory.getPair(usdt_test_address,wbnb);
    console.log("usdt/wbnb pair address:",usdt_bnb_pair_address);

    const usdt_bnb_Pair = await ethers.getContractAt("IUniswapV2Pair",usdt_bnb_pair_address);
    const reserves = await usdt_bnb_Pair.getReserves();
    console.log("usdt/wbnb  Reserves:", ethers.utils.formatEther(reserves[0].toString()), ethers.utils.formatEther(reserves[1].toString()));
    const lpBalance = await usdt_bnb_Pair.balanceOf(owner.address);
    console.log("lpBalance:", lpBalance);

    console.log("#########    remove usdt/wbnb liquidity    #########");
    const usdt = await  ethers.getContractAt("USDTTest",usdt_test_address);
    const info = await ethers.getContractAt("INFOErc20",infoerc20_address);
    
    const tx001 = await info.setExcludeFee(owner.address,true);
    await tx001.wait();

    const tx002 = await info.setExcludeFee(infoerc20_address,true);
    await tx002.wait();
     
    const deadline = Math.floor(Date.now() / 1000) + 60 * 10; // 10分钟

     // approve router 花费 LP Token
    // const approveTx = await usdt_bnb_Pair.connect(owner).approve(swapRouterAddress, lpBalance);
    // await approveTx.wait();

    // const allowance = await usdt_bnb_Pair.allowance(owner.address, swapRouterAddress);
    // console.log("LP Allowance:", allowance.toString());

    // const removeTx = await swapRouter.connect(owner).removeLiquidityETH(
    //     usdt_test_address, // ERC20 代币地址
    //     lpBalance,         // 要移除的 LP Token 数量
    //     0, 
    //     0, 
    //     owner.address,     // 收取资金的地址
    //     deadline,          // 交易截止时间
    //     { gasLimit: 3000000 }
    // );

    // try {
    //     await removeTx.wait(4);
    // } catch (err) {
    //     console.error(err); // ethers.js 会显示 revert 原因
    // }
    // console.log("Liquidity removed successfully!");

    // const reservesAfterRemove = await usdt_bnb_Pair.getReserves();
    // console.log("reservesAfterRemove:",reservesAfterRemove);

  console.log("#########    add usdt/wbnb liquidity    #########");
//  const tx21 = await usdt.connect(owner).approve(swapRouterAddress,ethers.utils.parseEther("1000"));
//  await tx21.wait();
//   const tx = await swapRouter.connect(owner).addLiquidityETH(
//         usdt_test_address,
//         ethers.utils.parseEther("1000"),
//         0, // 代币最小接收量（滑点保护）
//         0, // ETH最小接收量
//         owner.address,
//         deadline,
//         {
//             value: ethers.utils.parseEther("0.1") ,
//             gasLimit: 300000  // 手动设置Gas Limit
//         }
//     );
//     const reciept = await tx.wait();
//     // console.log("reciept:",reciept);
//     console.log("Liquidity added.");

//     const reservesAfterAdded = await usdt_bnb_Pair.getReserves();
//     console.log("reservesAfterAdded:",reservesAfterAdded);



}
main().catch(
    error => {
        console.log(error);
        process.exitCode = 1;
    }
);

/**
npx hardhat run ./scripts/info/bsctest/12removeLiquidity.ts --network bscTest

factory address: 0x6725F303b657a9451d8BA641348b6761A6CC7a17
wbnb address: 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd
usdt/wbnb pair address: 0x4dCa7367AAc18865A95545ebD84703C91A6d1609

 */