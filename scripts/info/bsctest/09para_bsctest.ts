import { id } from "ethers/lib/utils";
import { ethers, upgrades } from "hardhat";
import { INFOErc20,DepositContract,INFORewardDistribute,IUniswapV2Router02,IUniswapV2Factory} from  "../../../typechain-types";

async function main(){
    const erc20_address = "0x6aF6c51D87F41f9964D9b5Fcf718105Da306044e";
    const [owner,user1,user2] = await ethers.getSigners();
    // validate INFOErc20
    const erc20 = await ethers.getContractAt("INFOErc20",erc20_address) as INFOErc20;
    console.log("=================================  INFOERC20  ==============================");
    // #########    fee receiver
    console.log("#########    fee receiver     #########");
    console.log("BuyFeeReceiver0:",await erc20.getBuyFeeReceiver(0));
    console.log("BuyFeeReceiver1:",await erc20.getBuyFeeReceiver(1));
    console.log("BuyFeeReceiver2:",await erc20.getBuyFeeReceiver(2));
    console.log("BuyFeeReceiver3:",await erc20.getBuyFeeReceiver(3));

    console.log("SellFeeReceiver0:",await erc20.getSellFeeReceiver(0));
    console.log("SellFeeReceiver1:",await erc20.getSellFeeReceiver(1));
    console.log("SellFeeReceiver2:",await erc20.getSellFeeReceiver(2));
    console.log("SellFeeReceiver3:",await erc20.getSellFeeReceiver(3));

    // ######## 交易开关
    console.log("#########    交易开关     #########");
    console.log("检查交易是否整体开放tradeToPublic: ",await erc20.tradeToPublic());
    console.log("检查交易对购买开关 buyTradingEnabled: ",await erc20.getBuyTradingEnabled());
    console.log("检查交易对销售开关 sellTradingEnabled: ",await erc20.getSellTradingEnabled());
    console.log("检查普通转账交易开关 transTradingEnabled: ",await erc20.getTransTradingEnabled());



    console.log("=================================  查询流动性  ==============================");

    const usdt_test_address = "0x75A79414fcae320Ac6B063430239654b1a23A7Dd";
    const swapRouterAddress = "0xD99D1c33F9fC3444f8101754aBC46c52416550D1";
    const swapRouter = await ethers.getContractAt("IUniswapV2Router02",swapRouterAddress) as IUniswapV2Router02;
    const factoryAddress = await swapRouter.factory();
    console.log("factory address:",factoryAddress);
    const factory = await ethers.getContractAt("IUniswapV2Factory",factoryAddress) as IUniswapV2Factory;
    const wbnb = await swapRouter.WETH();
    console.log("wbnb address:",wbnb);
    console.log("#########    usdt/wbnb     #########");
    const usdt_bnb_pair_address = await factory.getPair(usdt_test_address,wbnb);
    console.log("usdt/wbnb pair address:",usdt_bnb_pair_address);

    const usdt_bnb_Pair = await ethers.getContractAt("IUniswapV2Pair",usdt_bnb_pair_address);
    const reserves = await usdt_bnb_Pair.getReserves();
    console.log("usdt/wbnb  Reserves:", ethers.utils.formatEther(reserves[0].toString()), ethers.utils.formatEther(reserves[1].toString()));
    const lpBalance = ethers.utils.formatEther(await usdt_bnb_Pair.balanceOf(owner.address));
    console.log("lpBalance:", lpBalance);

    console.log("#########    info/wbnb     #########");
    const info_bnb_Pair_address =  await factory.getPair(erc20_address,wbnb);
    console.log("info/wbnb pair address:",info_bnb_Pair_address);
    const info_bnb_Pair = await ethers.getContractAt("IUniswapV2Pair",info_bnb_Pair_address);
    const reserve2 = await info_bnb_Pair.getReserves();
    console.log("usdt/wbnb  Reserves:", ethers.utils.formatEther(reserve2[0].toString()), ethers.utils.formatEther(reserve2[1].toString()));
    const lpBalance2 = ethers.utils.formatEther(await usdt_bnb_Pair.balanceOf(owner.address));
    console.log("lpBalance:", lpBalance2);





    





}


main().catch(
    error => {
        console.log(error);
        process.exitCode = 1;
    }
);


/**
npx hardhat run ./scripts/info/bsctest/09para_bsctest.ts --network bscTest





 */