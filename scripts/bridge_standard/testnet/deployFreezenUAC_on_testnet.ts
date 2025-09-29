import { id } from "ethers/lib/utils";
import { ethers, upgrades } from "hardhat";

async function main(){
   const [owner] = await ethers.getSigners();
    const receiver = '0xb98E2E18259057076b3170c078F361978768d001';
    const router02_address = '0x32AEf11Bd9E1FBf8990CDB501b2632DA4fD76D01';
    const usdt_address = '0x3F00C9dd4F081D7b6b758555c621FbEb09d519FD';
    const buyFeeReceiver = '0xb98E2E18259057076b3170c078F361978768d001';
    const sellFeeReceiver = '0xb98E2E18259057076b3170c078F361978768d001';
    const wpijs = '0x0A8C16f9Ed042cf71BeB49e8d8854D189c704aDb';
    
    const uagFactory = await ethers.getContractFactory("FreezenUAC");
    const operator = '0xa984d62B1E8da0A2372348C01d4140B7BfCC5c29';
    
    // const uac = await uagFactory.deploy(receiver,usdt_address,router02_address,owner.address,owner.address,operator);
    // await uac.deployed();

    const uac = await ethers.getContractAt("FreezenUAC","0x7b3cBF0E94fD00624e2F6505a3B53A81f76d5CfF");
    console.log("FreezenUAC address is:",uac.address);

   // 设为禁用，加入全局白名单
   const tx1 = await uac.updateTradingEnabled();
   await tx1.wait();

   console.log("getTradingEnabled:",await uac.getTradingEnabled());
   const bridgeTargetContractAddress = "0xa984d62B1E8da0A2372348C01d4140B7BfCC5c29";
   const tx2 = await uac.updateWhitelist(bridgeTargetContractAddress,true);
   await tx2.wait();

   console.log("operator:",await uac.operator());
 

}


main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});

/***
 
npx hardhat run ./scripts/bridge_standard/testnet/deployFreezenUAC_on_testnet.ts --network pijstestnet

FreezenUAC address is: 0x7b3cBF0E94fD00624e2F6505a3B53A81f76d5CfF
 */