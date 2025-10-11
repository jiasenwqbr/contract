import { id } from "ethers/lib/utils";
import { ethers, upgrades } from "hardhat";

async function main(){

   const [owner] = await ethers.getSigners();
    const receiver = '0xb98E2E18259057076b3170c078F361978768d001';

   const router02_address = '0x32AEf11Bd9E1FBf8990CDB501b2632DA4fD76D01';
    const usdt_address = '0x3F00C9dd4F081D7b6b758555c621FbEb09d519FD';
    const wpijs = '0x0A8C16f9Ed042cf71BeB49e8d8854D189c704aDb';
   
    // const operator_address = '0xd4f0f0c79a35f217e5de4bff0752ba63cbc013e9';

    const uacFactory = await ethers.getContractFactory("UACToken");
    const uac = await uacFactory.deploy(receiver,usdt_address,router02_address,owner.address,wpijs);
    await uac.deployed();
    console.log("UAC address is:",uac.address);

    const tokenA = uac.address;
    const tokenB = "0x3F00C9dd4F081D7b6b758555c621FbEb09d519FD"; // USDT
    const factoryAddress = "0x113D5ef4c6FE6f2edBcF6915Bf7582c09F342499"; // PiJFactory
    const factory = await ethers.getContractAt("PiJFactory",factoryAddress);
    const pairAddress = await factory.getPair(tokenA, tokenB);
    console.log("UAC/USDT pairAddress is:",pairAddress);


     //    手续费
    const tx = await uac.setBuyFeeReceivers(
        ['0xd4f0f0c79a35f217e5de4bff0752ba63cbc013e9','0xd4f0f0c79a35f217e5de4bff0752ba63cbc013e9'],
        [10,10]
    );
    await tx.wait();

    const tx1 = await uac.setSellFeeReceivers(
         ['0xd4f0f0c79a35f217e5de4bff0752ba63cbc013e9','0xd4f0f0c79a35f217e5de4bff0752ba63cbc013e9'],
         [10,10]
    );
    await tx1.wait();

    const tx2 = await uac.batchUpdateGlobalWhitelist([owner.address,
        '0x466D44EFBf7F1035Feba1F0BdC6fEDE9Bd0729F4',
        '0xBDfb7B3cDDd4DE4F36fedFf836D25ED2365B146c'
    ],true,{
        gasLimit:12000000
    });
    await tx2.wait();



    const tokenContract = await ethers.getContractAt('UACToken','0x3b687Db4c7b77c6a508D4F0eFa756E508Fb2333F');
    // 币对是不是开放
    const tx21 = await  tokenContract.setPairsEnabledStatus('0x37166CA21e9a0Cafb27d558c1D7E5ffe5343B37C',true);
    await tx21.wait();
    // 交易是否公开
    const tx22 = await tokenContract.updateTradingEnabled(true);
    await tx22.wait();
    // 交易是否开启全局交易
    const tx23 = await tokenContract.setTradeToPublic(true);
    await tx23.wait();
    // 批量更新全局白名单
    const tx24 = await tokenContract.batchUpdateGlobalWhitelist([
        '0x4016DD5366ECF2F45AfA32db579daCcF30cd5B5f'
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
npx hardhat run ./scripts/bridge_standard/testnet/deployUAC_on_testnet_new.ts --network pijstestnet
UAC address is: 0x3b687Db4c7b77c6a508D4F0eFa756E508Fb2333F
UAC/USDT pairAddress is: 0x37166CA21e9a0Cafb27d558c1D7E5ffe5343B37C

 */