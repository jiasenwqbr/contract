import { id } from "ethers/lib/utils";
import { ethers, upgrades } from "hardhat";
import {SpritNFTT1,SpritNFTT3,NFTManage} from  "../../typechain-types";

async function main(){
    const [owner,operator] = await ethers.getSigners();
    let t1Address = '0xcD5296a4b66EDea63Ed963bE9426ac15bc98C41b';
    let t3Address = '0xE26b1b686a919a5acE30525606b60BD57Af71611';
    const args = [t1Address,t3Address];
    const spritNFTT1FTFactory = await ethers.getContractFactory("NFTManage");
    // const nFTManage = await upgrades.deployProxy(spritNFTT1FTFactory,args,{ kind:'uups'});
    const nFTManage = await upgrades.upgradeProxy('0x8B9b6f1F0458988363344e633Ad6a91add0a197B', spritNFTT1FTFactory, { kind: 'uups' });
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


    // update
    let feeReceiver = '0x517563100C7ceca8FfA85a50a53c61dc0Dd13E3f';
    let usdtAddress = '0x08aD141eadFC93cD4e1566c31E1fb49886D5b80B';
    let router = '0xDd682E7BE09F596F0D0DEDD53Eb75abffDcd2312';
    const devideMolecular = 1000;
    const tx3 = await nFTManage.setDevideMolecular(devideMolecular,{
                gasLimit: 1_000_000,
            });
    await tx3.wait();
    console.log("devideMolecular:",await nFTManage.gettDevideMolecular());

    const tx4 = await nFTManage.setFeeReceiver(feeReceiver,{
                gasLimit: 1_000_000,
            });
    await tx4.wait();
    console.log("feeReceiver:",await nFTManage.getFeeReceiver());
    const tx5 = await nFTManage.setUsdtAddress(usdtAddress,{
                gasLimit: 1_000_000,
            });
    await tx5.wait();
    console.log("usdtAddress:",await nFTManage.getUsdtAddress());
    const tx6 = await nFTManage.setSwapRouterAddress(router,{
                gasLimit: 1_000_000,
            });
    await tx6.wait();
    console.log("swapRouterAddress:",await nFTManage.getSwapRouterAddress());

    const tx7 = await nFTManage.setTokenAmountLimit(ethers.utils.parseEther('10'),{
                gasLimit: 1_000_000,
            });
    await tx7.wait();
    console.log("TokenAmountLimit:",await nFTManage.getTokenAmountLimit());


}


main().catch(error => {
    console.log(error);
    process.exitCode = 1;
});

/**
 npx hardhat run ./scripts/nft/deploy_NFTManage_on_mainnet.ts --network pijs

SpritNFTT1 address is: 0xcD5296a4b66EDea63Ed963bE9426ac15bc98C41b
SpritNFTT3 address is: 0xE26b1b686a919a5acE30525606b60BD57Af71611
NFTManage contract address: 0x8B9b6f1F0458988363344e633Ad6a91add0a197B



 */

