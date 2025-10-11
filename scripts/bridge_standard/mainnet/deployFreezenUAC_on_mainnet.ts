import { id } from "ethers/lib/utils";
import { ethers, upgrades } from "hardhat";

async function main(){
   const [owner] = await ethers.getSigners();
    const receiver = '0x727522774ADBD3340E8D420f8d0F45100A3863e1';
   
   
    const operator = '0x18E11768B9178FB2bdF299020653154550095dE3';  // 设为 bridgeTargetContractAddress

    const wpijs = '0x30FF9d7E86Cbc55E970a6835248b30B21BD1390E';
    const router02_address = '0xDd682E7BE09F596F0D0DEDD53Eb75abffDcd2312';
    const usdt_address = '0x08aD141eadFC93cD4e1566c31E1fb49886D5b80B';
    
    const uagFactory = await ethers.getContractFactory("FreezenUAC");
   
    
    const fuac = await uagFactory.deploy(receiver,usdt_address,router02_address,owner.address,owner.address,operator);
    await fuac.deployed();

    // const fuac = await ethers.getContractAt("FreezenUAC","0x7b3cBF0E94fD00624e2F6505a3B53A81f76d5CfF");
    console.log("FreezenUAC address is:",fuac.address);

   // 设为禁用，加入全局白名单
   const tx1 = await fuac.updateTradingEnabled();
   await tx1.wait();

   console.log("getTradingEnabled:",await fuac.getTradingEnabled());
   const bridgeTargetContractAddress = "0x18E11768B9178FB2bdF299020653154550095dE3";
   const tx2 = await fuac.updateWhitelist(bridgeTargetContractAddress,true);
   await tx2.wait();

   const tx3 = await fuac.setOperator(bridgeTargetContractAddress);
   await tx3.wait();
   
   console.log("operator:",await fuac.operator());
 

}


main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});

/***
 
npx hardhat run ./scripts/bridge_standard/mainnet/deployFreezenUAC_on_mainnet.ts --network pijs
FreezenUAC address is: 0x06AFAbcB72B6CD411c4Cc6768272B6B7eB445bAC
 */