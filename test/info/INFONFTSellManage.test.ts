import { expect } from "chai";
import { ethers, upgrades } from "hardhat";
import { AsiaTelevisionINFONFT,INFONFTSellManage,RecommendationINFO,USDTTest } from "../../typechain-types";
import { network } from "hardhat";
import { Signer } from "ethers";


describe("INFONFTSellManage.test",()=>{
    let owner:any;
    let user1:any;
    let user2:any;
    let user3:any;
    let user4:any;
    const usdt_address = "0xD8703021d43420c19Ba393501574B2250732060d";
    const nft_address = "0x9D36918d5313A8156108c14dFaAB496Ab1d4DF10";
    let receiver:any;
    let rootRecommender:any;
    const recommandContractAddress = "0x976d1123294D237c1dD0E5E62B968F447E90e6Ce";
    const nftSell_address = "0xb4502B3F2d65Ec512297B2c9A992A47DF0410F4d";
    let usdt:USDTTest;
    let nft:AsiaTelevisionINFONFT;
    let recommand:RecommendationINFO;
    let nftSellManage:INFONFTSellManage;
    beforeEach(async() => {
        [owner,user1,user2,user3,user4] = await ethers.getSigners();
        receiver = user1.address;
        rootRecommender = user2.address;
        usdt = await ethers.getContractAt("USDTTest",usdt_address) as USDTTest;
        nft = await ethers.getContractAt("AsiaTelevisionINFONFT",nft_address) as AsiaTelevisionINFONFT;
        recommand = await ethers.getContractAt("RecommendationINFO",recommandContractAddress) as RecommendationINFO;
        nftSellManage = await ethers.getContractAt("INFONFTSellManage",nftSell_address) as INFONFTSellManage;

        console.log("owner address:",owner.address);
        console.log("user1 address:",user1.address);
        console.log("user2 address:",user2.address);
        console.log("user3 address:",user3.address);
        console.log("user4 address:",user4.address);
    });

    it("test owner bindRelationShip",async () => {
        const tx = await recommand.connect(owner).bindRelationShip(rootRecommender,{
         gasLimit:6721975
        });
        await tx.wait();
        console.log("binder info:",await recommand.getUserInfo(owner.address));
    });

    it("test user1 bindRelationShip",async () => {
        const tx = await recommand.connect(user1).bindRelationShip(rootRecommender,{
         gasLimit:6721975
        });
        await tx.wait();
        console.log("binder info:",await recommand.getUserInfo(user1.address));
    });
    it("test user3 bindRelationShip",async () => {
        const tx = await recommand.connect(user3).bindRelationShip(user1.address,{
         gasLimit:6721975
        });
        await tx.wait();
        console.log("binder info:",await recommand.getUserInfo(user3.address));
        console.log("user1 info:",await recommand.getUserInfo(user1.address));
    });
    
    it("test root bindRelationShip",async () => {
        console.log("binder info:",await recommand.getUserInfo(rootRecommender));
    });

    it("buyNFT",async () => {

        console.log("before buy owner balance:",ethers.utils.formatEther(await usdt.balanceOf(owner.address)));
        console.log("before buy receiver balance:",ethers.utils.formatEther(await usdt.balanceOf(receiver)));

        const tx = await usdt.connect(owner).approve(nftSellManage.address,ethers.utils.parseEther("1000"));
        await tx.wait();

        const tx1 = await nftSellManage.connect(owner).buyNode(usdt_address,ethers.utils.parseEther("1000"),rootRecommender,{
            gasLimit:6721975
        });
        await tx.wait();

        console.log("after buy owner balance:",ethers.utils.formatEther(await usdt.balanceOf(owner.address)));
        console.log("after buy receiver balance:",ethers.utils.formatEther(await usdt.balanceOf(receiver)));

        console.log("after buy owner nft balance:",ethers.utils.formatEther(await nft.balanceOf(owner.address)));


    });

    it("buyResult",async () => {
        console.log("after buy owner balance:",ethers.utils.formatEther(await usdt.balanceOf(owner.address)));
        console.log("after buy receiver balance:",ethers.utils.formatEther(await usdt.balanceOf(receiver)));

        console.log("after buy owner nft balance:",ethers.utils.formatEther(await nft.balanceOf(owner.address)));
        console.log("after buy owner nft id:",await nftSellManage.getUserNFT(owner.address));

    });

    it("buyNFT2",async () => {

        console.log("before buy owner balance:",ethers.utils.formatEther(await usdt.balanceOf(user1.address)));
        console.log("before buy receiver balance:",ethers.utils.formatEther(await usdt.balanceOf(receiver)));

        const tx = await usdt.connect(user1).approve(nftSellManage.address,ethers.utils.parseEther("1000"));
        await tx.wait();

        const tx1 = await nftSellManage.connect(user1).buyNode(usdt_address,ethers.utils.parseEther("1000"),rootRecommender,{
            gasLimit:6721975
        });
        await tx.wait();

        console.log("after buy owner balance:",ethers.utils.formatEther(await usdt.balanceOf(owner.address)));
        console.log("after buy receiver balance:",ethers.utils.formatEther(await usdt.balanceOf(receiver)));

        console.log("after buy owner nft balance:",ethers.utils.formatEther(await nft.balanceOf(owner.address)));


    });

    


});

/**
 
npx hardhat test ./test/info/INFONFTSellManage.test.ts --network ganache

npx hardhat test ./test/info/INFONFTSellManage.test.ts --network ganache --grep "buyNFT"
 */