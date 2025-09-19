import { expect } from "chai";
import { ethers, upgrades } from "hardhat";
import { SpritNFTT1,SpritNFTT3,NFTManage } from "../../typechain-types";
import { network } from "hardhat";
import { Signer } from "ethers";

describe("NFTManage",()=>{
    let owner:any;
    let user1:any;
    let user2:any;
    let user3:any;
    let nftManage:NFTManage;
    let nftManageAddress:any;
    let nft1:SpritNFTT1;
    let nft3:SpritNFTT3;
    let nft1Address:any;
    let nft3Address:any;
    const fs = require("fs");

    beforeEach(async () => {
        [owner,user1, user2,user3] = await ethers.getSigners();
        nftManageAddress = "0xd55Bd1a1F2A68F720532850B975ec31859F69829";
        nft1Address = "0xaCcc527C8b85830d4C1c49ceC16D35c74a02ce84";
        nft3Address = "0x9ba4B9e1cC6dbE771336beaB21486D787bF7Cc48";
        nftManage = await ethers.getContractAt("NFTManage",nftManageAddress) as NFTManage;
        nft1 = await ethers.getContractAt("SpritNFTT1",nft1Address) as SpritNFTT1;
        nft3 = await ethers.getContractAt("SpritNFTT3",nft3Address) as SpritNFTT3;

        // const tx1 = await nft1.setMaxImageBytes(1024 * 1024);
        // await tx1.wait();
        // const tx2 = await nft3.setMaxImageBytes(1024 * 1024);
        // await tx2.wait();

        // console.log(await nft1.maxImageBytes());
        // console.log(await nft3.maxImageBytes());


    });

    // describe("Test mint", () => {
    //     beforeEach(async () => {
    //         const imgPath = "/Users/jason/Desktop/bak/wechat_2025-09-18_112933_691.png";
    //         const name = "t1 nft";
    //         const desc = "t1 nft stored on-chain";
    //         const tx = await nftManage.connect(owner).mintNFT(1,imgPath, name, desc, {
    //            gasLimit:12000000
    //         });
    //         console.log("tx:",tx);
    //         const recipt = await tx.wait();
    //         console.log("recipt:",recipt);
    //     });
    //     it("test mint nft if is exist",async () => {
    //         console.log(await nft1.maxImageBytes());
    //         console.log(await nft3.maxImageBytes());
    //     });
    // });

    describe("get minted nft",() => {
        beforeEach(async () => {
            const ids = await nft1.getUserNFTs(owner.address);
            console.log("ids:",ids);
            console.log("ids:",ids[0].toString());
            
            const mynft = await nft1.getNFTByTokenId(10);
            console.log("mynft :",mynft);
            console.log("mynft name :",mynft.name);
            console.log("mynft image:",mynft.image);
            console.log("mynft description:",mynft.description);
        });
        it("balance of user",async () => {
            console.log("nft1",await nft1.balanceOf(owner.address));
            console.log("nft3:",await nft3.balanceOf(owner.address));
        })
    });

});


/**


npx hardhat test ./test/nft/NFTManage.test.ts --network pijstestnet

SpritNFTT1 address is: 0xaCcc527C8b85830d4C1c49ceC16D35c74a02ce84
SpritNFTT3 address is: 0x9ba4B9e1cC6dbE771336beaB21486D787bF7Cc48
NFTManage contract address: 0xd55Bd1a1F2A68F720532850B975ec31859F69829

 */
