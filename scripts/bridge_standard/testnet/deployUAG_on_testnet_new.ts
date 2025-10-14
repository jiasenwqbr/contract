import { id } from "ethers/lib/utils";
import { ethers, upgrades } from "hardhat";

async function main(){

    const [owner] = await ethers.getSigners();
    const receiver = '0xb98E2E18259057076b3170c078F361978768d001';

    const router02_address = '0x32AEf11Bd9E1FBf8990CDB501b2632DA4fD76D01';
    const usdt_address = '0x3F00C9dd4F081D7b6b758555c621FbEb09d519FD';
    const wpijs = '0x0A8C16f9Ed042cf71BeB49e8d8854D189c704aDb';
   
    // const operator_address = '0xd4f0f0c79a35f217e5de4bff0752ba63cbc013e9';

    // const uagFactory = await ethers.getContractFactory("UAGERC20");
    // const uag = await uagFactory.deploy(receiver,usdt_address,router02_address,owner.address,wpijs);
    // await uag.deployed();
    // console.log("UAG address is:",uag.address);

    const tokenA = "0xACfB54616A301c205375d8001a4F8ddc4CD143D5";
    const tokenB = "0xcbc3c74559aeaECFe73EF1B7072dD8F73c65B7c0"; // USDT
    const factoryAddress = "0x113D5ef4c6FE6f2edBcF6915Bf7582c09F342499"; // PiJFactory
    const factory = await ethers.getContractAt("PiJFactory",factoryAddress);
    // const tx00 = await factory.createPair(tokenA, tokenB);
    // await tx00.wait();
    const pairAddress = await factory.getPair(tokenA, tokenB);
    console.log("UAG/USDT pairAddress is:",pairAddress);


    const tokenContract = await ethers.getContractAt('UAGERC20','0xACfB54616A301c205375d8001a4F8ddc4CD143D5');
    // 设置成pair
    const tx20 = await tokenContract.setPair('0xb71b95D88174BD6b72f4fB4529eA53420e3bf947',true);
    await tx20.wait();
    // 币对是不是开放
    const tx21 = await  tokenContract.setPairsEnabledStatus('0xb71b95D88174BD6b72f4fB4529eA53420e3bf947',true);
    await tx21.wait();
    // 交易是否公开
    const tx22 = await tokenContract.updateTradingEnabled(true);
    await tx22.wait();
    // 交易是否开启全局交易
    const tx23 = await tokenContract.setTradeToPublic(true);
    await tx23.wait();
    // 批量更新全局白名单
    const tx24 = await tokenContract.batchUpdateGlobalWhitelist([
        '0xb98E2E18259057076b3170c078F361978768d001',
        '0xe02D3558765e603bDaAB3b2d38A4714aA8ce9159'
    ],true,{
        gasLimit:12000000
    });
    await tx24.wait();




}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});

/***
 * 
npx hardhat run ./scripts/bridge_standard/testnet/deployUAG_on_testnet_new.ts --network pijstestnet
UAG address is: 0xACfB54616A301c205375d8001a4F8ddc4CD143D5
UAG/USDT pairAddress is: 0xb71b95D88174BD6b72f4fB4529eA53420e3bf947

 */