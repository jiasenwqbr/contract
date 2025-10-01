import { id } from "ethers/lib/utils";
import { ethers, upgrades } from "hardhat";
import {SpritNFTT1,SpritNFTT3,NFTManage} from  "../../typechain-types";

async function main(){
    const [owner,operator] = await ethers.getSigners();
    let t1Address = '0xaCcc527C8b85830d4C1c49ceC16D35c74a02ce84';
    let t3Address = '0x9ba4B9e1cC6dbE771336beaB21486D787bF7Cc48';
    const args = [t1Address,t3Address];
    const spritNFTT1FTFactory = await ethers.getContractFactory("NFTManage");
    // const nFTManage = await upgrades.deployProxy(spritNFTT1FTFactory,args,{ kind:'uups'});
    const nFTManage = await upgrades.upgradeProxy('0xd55Bd1a1F2A68F720532850B975ec31859F69829', spritNFTT1FTFactory, { kind: 'uups' });
    await nFTManage.deployed();
    console.log("NFTManage contract address:",nFTManage.address);
    

    const spritNFTT1 = await ethers.getContractAt("SpritNFTT1",t1Address) as SpritNFTT1;
    const tx1 = await spritNFTT1.grantRole(await spritNFTT1.OPERATOR_ROLE(),nFTManage.address);
    await tx1.wait();
    const hasRole = await spritNFTT1.hasRole(await spritNFTT1.OPERATOR_ROLE(),nFTManage.address);
    console.log("hasRole:",hasRole);

    const spritNFTT3 = await ethers.getContractAt("SpritNFTT3",t3Address) as SpritNFTT3;
    const tx2 = await spritNFTT3.grantRole(await spritNFTT3.OPERATOR_ROLE(),nFTManage.address);
    await tx2.wait();
    const hasRole3 = await spritNFTT3.hasRole(await spritNFTT3.OPERATOR_ROLE(),nFTManage.address);
    console.log("hasRole3:",hasRole3);
    
    let feeReceiver = owner.address;
    let usdtAddress = '0x3F00C9dd4F081D7b6b758555c621FbEb09d519FD';
    let router = '0x32AEf11Bd9E1FBf8990CDB501b2632DA4fD76D01';
    // update
    const tx3 = await nFTManage.setDevideMolecular(500);
    await tx3.wait();
    console.log("devideMolecular:",await nFTManage.gettDevideMolecular());

    const tx4 = await nFTManage.setFeeReceiver(feeReceiver);
    await tx4.wait();
    console.log("feeReceiver:",await nFTManage.getFeeReceiver());
    const tx5 = await nFTManage.setUsdtAddress(usdtAddress);
    await tx5.wait();
    console.log("usdtAddress:",await nFTManage.getUsdtAddress());
    const tx6 = await nFTManage.setSwapRouterAddress(router);
    await tx6.wait();
    console.log("swapRouterAddress:",await nFTManage.getSwapRouterAddress());

}


main().catch(error => {
    console.log(error);
    process.exitCode = 1;
});

/**
 npx hardhat run ./scripts/nft/deploy_NFTManage_on_testnet.ts --network pijstestnet


SpritNFTT1 address is: 0xaCcc527C8b85830d4C1c49ceC16D35c74a02ce84
SpritNFTT3 address is: 0x9ba4B9e1cC6dbE771336beaB21486D787bF7Cc48
NFTManage contract address: 0xd55Bd1a1F2A68F720532850B975ec31859F69829

 */

