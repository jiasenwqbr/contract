import { id } from "ethers/lib/utils";
import { ethers, upgrades } from "hardhat";
import { INFOErc20,DepositContract,INFORewardDistribute,IUniswapV2Router02,IUniswapV2Factory,USDTTest,IUniswapV2Pair} from  "../../../typechain-types";

async function main(){
     const [owner,user1,user2] = await ethers.getSigners();
    const infoerc20_address = "0x414eC87C4c27fE1c382333b6838D571AbBd5C32c";
    const usdt_test_address = "0x43Db2F7e34F8583b2eEd39681bC77C2699f15A6d";
    const swapRouterAddress = "0xD99D1c33F9fC3444f8101754aBC46c52416550D1";



    // 创建usdt、wbnb交易对
    const swapRouter = await ethers.getContractAt("IUniswapV2Router02",swapRouterAddress) as IUniswapV2Router02;
    const factoryAddress = await swapRouter.factory();
    console.log("factory address:",factoryAddress);
    const factory = await ethers.getContractAt("IUniswapV2Factory",factoryAddress) as IUniswapV2Factory;
    const wbnb = await swapRouter.WETH();
    console.log("wbnb address:",wbnb);
    // const tx11 = await factory.createPair(usdt_test_address,wbnb);
    // await tx11.wait();
    const pair = await factory.getPair(usdt_test_address,wbnb);
    console.log("usdt/wbnb pair address:",pair);

    const ownerBNBbalance =  await ethers.provider.getBalance(owner.address);
    console.log("owner bnb balance :",ethers.utils.formatEther(ownerBNBbalance));

    const usdt = await ethers.getContractAt("USDTTest",usdt_test_address);
    console.log("owner usdt balance :",ethers.utils.formatEther(await usdt.balanceOf(owner.address)));

    const deadline = Math.floor(Date.now() / 1000) + 60 * 10; // 10分钟
    // // 添加流动性
    // const tx21 = await usdt.connect(owner).approve(swapRouterAddress,ethers.utils.parseEther("1000000"));
    // await tx21.wait();
    
    // const allowance = await usdt.allowance(owner.address, swapRouterAddress);
    // const tx = await swapRouter.connect(owner).addLiquidityETH(
    //     usdt_test_address,
    //     ethers.utils.parseEther("1000000"),
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

    console.log("add liquidity info/bnb ");

    const info = await ethers.getContractAt("INFOErc20",infoerc20_address);
    const tx0 = await info.setTradeToPublic(true);

    await tx0.wait();

    const tx01 = await info.setExcludeFee(owner.address,true);
    await tx01.wait();
    const tx21 = await info.connect(owner).approve(swapRouterAddress,ethers.utils.parseEther("1000000"));
    await tx21.wait();
    
    const allowance = await info.allowance(owner.address, swapRouterAddress);
    const tx = await swapRouter.connect(owner).addLiquidityETH(
        infoerc20_address,
        ethers.utils.parseEther("500000"),
        0, // 代币最小接收量（滑点保护）
        0, // ETH最小接收量
        owner.address,
        deadline,
        {
            value: ethers.utils.parseEther("0.05") ,
            gasLimit: 300000  // 手动设置Gas Limit
        }
    );
    const reciept = await tx.wait();
    console.log("Liquidity added.");
    const info_bnb_PairAddress = await factory.getPair(infoerc20_address,wbnb);
    const info_bnb_Pair = await ethers.getContractAt("IUniswapV2Pair",info_bnb_PairAddress);
    const usdtreserves = await info_bnb_Pair.getReserves();
    console.log("Reserves:", ethers.utils.formatEther(usdtreserves[0].toString()), ethers.utils.formatEther(usdtreserves[1].toString()));
    const lpBalance1 = ethers.utils.formatEther(await info_bnb_Pair.balanceOf(owner.address));
    console.log("lpBalance:", lpBalance1);

    // 移除流动性
//     const info_bnb_PairAddress = await factory.getPair(infoerc20_address,wbnb);
//    const pairAddress = info_bnb_PairAddress; // 之前创建的 INFO/WBNB 交易对
//     const pairContract = await ethers.getContractAt("IUniswapV2Pair", pairAddress);

//     // 查询 LP Token 余额
//     const lpBalance1 = await pairContract.balanceOf(owner.address);
//     console.log("LP Token Balance:", ethers.utils.formatEther(lpBalance1));

//     // approve router 花费 LP Token
//     const approveTx = await pairContract.connect(owner).approve(swapRouterAddress, lpBalance1);
//     await approveTx.wait();

//     const allowance = await pairContract.allowance(owner.address, swapRouterAddress);
//     console.log("LP Allowance:", allowance.toString());

//     console.log(await pairContract.balanceOf(owner.address));


//     const removeTx = await swapRouter.connect(owner).removeLiquidityETH(
//         infoerc20_address, // ERC20 代币地址
//         lpBalance1,         // 要移除的 LP Token 数量
//         lpBalance1.mul(90).div(100), // token 最小接收量 98%
//         ethers.utils.parseEther("0.09"), // ETH 最小接收量 90% 预期
//         owner.address,     // 收取资金的地址
//         deadline,          // 交易截止时间
//         { gasLimit: 3000000 }
//     );

//     try {
//         await removeTx.wait();
//     } catch (err) {
//         console.error(err); // ethers.js 会显示 revert 原因
//     }
//     console.log("Liquidity removed successfully!");


    


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