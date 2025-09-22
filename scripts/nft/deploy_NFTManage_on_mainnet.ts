import { id } from "ethers/lib/utils";
import { ethers, upgrades } from "hardhat";
import {SpritNFTT1,SpritNFTT3,NFTManage} from  "../../typechain-types";

async function main(){
    const [owner,operator] = await ethers.getSigners();
    let t1Address = '0xcD5296a4b66EDea63Ed963bE9426ac15bc98C41b';
    let t3Address = '0xE26b1b686a919a5acE30525606b60BD57Af71611';
    const args = [t1Address,t3Address];
    const spritNFTT1FTFactory = await ethers.getContractFactory("NFTManage");
    const nFTManage = await upgrades.deployProxy(spritNFTT1FTFactory,args,{ kind:'uups'});
    //const nFTManage = await upgrades.upgradeProxy('0xd55Bd1a1F2A68F720532850B975ec31859F69829', spritNFTT1FTFactory, { kind: 'uups' });
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

