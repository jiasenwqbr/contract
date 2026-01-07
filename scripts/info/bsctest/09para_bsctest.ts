import { id } from "ethers/lib/utils";
import { ethers, upgrades } from "hardhat";
import { INFOErc20,DepositContract,INFORewardDistribute } from  "../../../typechain-types";

async function main(){
    const erc20_address = "0xA101A785948F9ebda1CA2D0E09f5eD21e6B0e87b";
    // validate INFOErc20
    const erc20 = await ethers.getContractAt("INFOErc20",erc20_address) as INFOErc20;
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