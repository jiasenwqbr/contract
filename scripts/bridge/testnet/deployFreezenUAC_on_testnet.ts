import { id } from "ethers/lib/utils";
import { ethers, upgrades } from "hardhat";

async function main(){
    const [owner] = await ethers.getSigners();
    const receiver = '0xBB5EAccCEB5CBCfBD73d8Fb6bBd122eACa47ae37';
    const router02_address = '0x32AEf11Bd9E1FBf8990CDB501b2632DA4fD76D01';
    const uagFactory = await ethers.getContractFactory("FreezenUAC");
    const usdt_address = '0x3F00C9dd4F081D7b6b758555c621FbEb09d519FD';
    const buyFeeReceiver = '0xBB5EAccCEB5CBCfBD73d8Fb6bBd122eACa47ae37';
    const sellFeeReceiver = '0xBB5EAccCEB5CBCfBD73d8Fb6bBd122eACa47ae37';
    const operator_address = '0xd4f0f0c79a35f217e5de4bff0752ba63cbc013e9';
    // const uac = await uagFactory.deploy(receiver,usdt_address,router02_address,buyFeeReceiver,sellFeeReceiver,operator_address);
    // await uac.deployed();

    const uac = await ethers.getContractAt("FreezenUAC","0x1fA9ec12EfC20EC0c22C94d8c915cB788c4e3A15");
    console.log("FreezenUAC address is:",uac.address);

   // 设为禁用，加入全局白名单
   const tx1 = await uac.updateTradingEnabled();
   await tx1.wait();

   console.log("getTradingEnabled:",await uac.getTradingEnabled());
   const bridgeTargetContractAddress = "0xa984d62B1E8da0A2372348C01d4140B7BfCC5c29";
   const tx2 = await uac.updateWhitelist(bridgeTargetContractAddress,true);
   await tx2.wait();


}


main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});

/***
 
npx hardhat run ./scripts/bridge/testnet/deployFreezenUAC_on_testnet.ts --network pijstestnet

FreezenUAC address is: 0x1fA9ec12EfC20EC0c22C94d8c915cB788c4e3A15
 */