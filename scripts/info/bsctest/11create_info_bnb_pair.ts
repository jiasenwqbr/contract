import { id } from "ethers/lib/utils";
import { ethers, upgrades } from "hardhat";
import { INFOErc20,DepositContract,INFORewardDistribute,IUniswapV2Router02,IUniswapV2Factory,USDTTest,IUniswapV2Pair} from  "../../../typechain-types";

async function main(){
    const [owner,user1,user2] = await ethers.getSigners();
    const infoerc20_address = "0x1B9D597997DC0BC1b41786556a48C976866B5B64";
    const usdt_test_address = "0x75A79414fcae320Ac6B063430239654b1a23A7Dd";
    const swapRouterAddress = "0xD99D1c33F9fC3444f8101754aBC46c52416550D1";
    const depositC = "0xc4f7F567838918610D4481cF875495Da241A352c";



    // 创建usdt、wbnb交易对
    const swapRouter = await ethers.getContractAt("IUniswapV2Router02",swapRouterAddress) as IUniswapV2Router02;
    const factoryAddress = await swapRouter.factory();
    console.log("factory address:",factoryAddress);
    const factory = await ethers.getContractAt("IUniswapV2Factory",factoryAddress) as IUniswapV2Factory;
    const wbnb = await swapRouter.WETH();
    console.log("wbnb address:",wbnb);
    // const tx11 = await factory.createPair(infoerc20_address,wbnb);
    // await tx11.wait();
    const pair = await factory.getPair(infoerc20_address,wbnb);
    console.log("info/wbnb pair address:",pair);
    
    const info = await ethers.getContractAt("INFOErc20",infoerc20_address);
    const tx001 = await info.setExcludeFee(owner.address,true);
    await tx001.wait();

    const tx002 = await info.setExcludeFee(infoerc20_address,true);
    await tx002.wait();
     const tx003 = await info.setExcludeFee(infoerc20_address,true);
    await tx003.wait();

    const deadline = Math.floor(Date.now() / 1000) + 60 * 10; // 10分钟
    // // // 添加流动性
    const tx21 = await info.connect(owner).approve(swapRouterAddress,ethers.utils.parseEther("1000000"));
    await tx21.wait();
    
    const tx = await swapRouter.connect(owner).addLiquidityETH(
        infoerc20_address,
        ethers.utils.parseEther("50000"),
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
    // console.log("reciept:",reciept);
    console.log("Liquidity added.");





    //  // 移除流动性
    // const info_bnb_PairAddress = await factory.getPair(infoerc20_address,wbnb);
    // const pairAddress = info_bnb_PairAddress; // 之前创建的 INFO/WBNB 交易对
    // const pairContract = await ethers.getContractAt("IUniswapV2Pair", pairAddress);

    // // 查询 LP Token 余额
    // const lpBalance1 = await pairContract.balanceOf(owner.address);
    // console.log("LP Token Balance:", ethers.utils.formatEther(lpBalance1));

    // // approve router 花费 LP Token
    // const approveTx = await pairContract.connect(owner).approve(swapRouterAddress, lpBalance1);
    // await approveTx.wait();

    // const allowance = await pairContract.allowance(owner.address, swapRouterAddress);
    // console.log("LP Allowance:", allowance.toString());

    // console.log(await pairContract.balanceOf(owner.address));

    // // const deadline = Math.floor(Date.now() / 1000) + 60 * 10; // 10分钟
    // const removeTx = await swapRouter.connect(owner).removeLiquidityETH(
    //     infoerc20_address, // ERC20 代币地址
    //     lpBalance1,         // 要移除的 LP Token 数量
    //     lpBalance1.mul(90).div(100), // token 最小接收量 98%
    //     ethers.utils.parseEther("0.04"), // ETH 最小接收量 90% 预期
    //     owner.address,     // 收取资金的地址
    //     deadline,          // 交易截止时间
    //     { gasLimit: 3000000 }
    // );

    // try {
    //     await removeTx.wait();
    // } catch (err) {
    //     console.error(err); // ethers.js 会显示 revert 原因
    // }
    // console.log("Liquidity removed successfully!");



}
main().catch(
    error => {
        console.log(error);
        process.exitCode = 1;
    }
);


/**
npx hardhat run ./scripts/info/bsctest/11create_info_bnb_pair.ts --network bscTest

factory address: 0x6725F303b657a9451d8BA641348b6761A6CC7a17
wbnb address: 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd
usdt/wbnb pair address: 0x4dCa7367AAc18865A95545ebD84703C91A6d1609




 */