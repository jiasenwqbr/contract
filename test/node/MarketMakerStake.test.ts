import { expect } from "chai";
import { ethers, upgrades } from "hardhat";
import { UAC,UAGToken,StakingUAG,MarketMakerStake,IERC20,PIJS_USDT } from "../../typechain-types";
import { network } from "hardhat";
import { Signer } from "ethers";


describe("MarketMakerStake",() => {
    let owner:any;
    let user1:any;
    let user2:any;
    let user3:any;
    let uac:UAC;
    let uag:UAGToken;
    let stakingUAG:StakingUAG;
    let marketMakerStake:MarketMakerStake;
    let uag_address:any;
    let uac_address:any;
    let usdtAddress:any;
    let feeAddress:any;
    let signer:any;
    let usdt:PIJS_USDT;
    beforeEach(async () => {
        [owner,user1, user2,user3] = await ethers.getSigners();
        uac_address = "0xe15B602eF891D45251FF749BE97db6a983CdE175";
        uag_address = "0xc9Ee4524690631FF44f3e7104bF1d08E5c119f1b";
        usdtAddress = "0x3F00C9dd4F081D7b6b758555c621FbEb09d519FD";
        feeAddress = owner.address;
        signer = owner.address;
        // deploy uac
        uac = await ethers.getContractAt("UAC",uac_address) as UAC;
        // deploy uag
        uag = await ethers.getContractAt("UAG",uag_address) as UAGToken;
        usdt = await ethers.getContractAt("PIJS_USDT",usdtAddress) as PIJS_USDT;
        // deploy StakingUAG
        const args = [signer,uac_address,uag_address,usdtAddress,feeAddress];
        const marketMakerStakeFactory = await ethers.getContractFactory('MarketMakerStake');
        // marketMakerStake =  (await upgrades.deployProxy(marketMakerStakeFactory,args,{kind:'uups'})) as MarketMakerStake;
        // marketMakerStake = await upgrades.upgradeProxy('0x43c9E6220cFbF697B4b0fb101fC0205cB5D01f65', marketMakerStakeFactory, { kind: 'uups' }) as MarketMakerStake;
        // await marketMakerStake.deployed();
        marketMakerStake = await ethers.getContractAt("MarketMakerStake","0x43c9E6220cFbF697B4b0fb101fC0205cB5D01f65") as MarketMakerStake;
        console.log("MarketMakerStake address is:",marketMakerStake.address);
    });
    describe("test stake",() => {
        let beforeUsdtBalance:any;
        let beforeContractBalance:any;
        beforeEach(async () => {
            const  params = {
                orderId:2,
                caller:owner.address,
                tokenAddress:usdtAddress,
                amount:ethers.utils.parseEther("10"),
                startTimestamp: Math.floor(Date.now() / 1000),
                endTimestamp: Math.floor(Date.now() / 1000) + 2592000,
                stakeType:2592000,
                renewable:0
        
            };

            const types = {
                Permit: [
                    { name: "orderId", type: "uint256" },
                    { name: "caller", type: "address" },
                    { name: "tokenAddress", type: "address" },
                    { name: "amount", type: "uint256" },
                    { name: "startTimestamp", type: "uint256" },
                    { name: "endTimestamp", type: "uint256" },
                    { name: "stakeType", type: "uint256" },
                    { name: "renewable", type: "uint256" },
                ],
            };
            const domain = {
                name: "MarketMakerStake",
                version: "1",
                chainId: (await ethers.provider.getNetwork()).chainId,
                verifyingContract: marketMakerStake.address,
            };
            const signature = await owner._signTypedData(domain, types, params);
            const data = ethers.utils.defaultAbiCoder.encode(
                [
                    "uint256",
                    "address",
                    "address",
                    "uint256", 
                    "uint256", 
                    "uint256",
                    "uint256", 
                    "uint256",
                    "bytes"
                ],[
                    params.orderId,
                    params.caller,
                    params.tokenAddress,
                    params.amount,
                    params.startTimestamp,
                    params.endTimestamp,
                    params.stakeType,
                    params.renewable,
                    signature
                ]
            );
            beforeUsdtBalance = await usdt.balanceOf(owner.address);
            beforeContractBalance = await usdt.balanceOf(marketMakerStake.address);
            console.log("beforeUsdtBalance:",beforeUsdtBalance);
            console.log("beforeContractBalance:",beforeContractBalance);

            const tx1 = await usdt.connect(owner).approve(marketMakerStake.address,ethers.utils.parseEther("100"));
            await tx1.wait();
            const allowance = await usdt.allowance(owner.address, marketMakerStake.address);
            console.log("Current allowance:", allowance.toString());
            const tx = await marketMakerStake.stake(data,{
                gasLimit:1_000_000
            });
            const receipt = await tx.wait();
            console.log("receipt.transactionHash:",receipt.transactionHash);

        });
        it("After stake", async () => {
            const afterUsdtBalance = await usdt.balanceOf(owner.address);
            const afterContractBalance = await usdt.balanceOf(marketMakerStake.address);
            console.log("afterUsdtBalance:",afterUsdtBalance);
            console.log("afterContractBalance:",afterContractBalance);
        });
    });
    describe("unStake",() => {
        beforeEach(async () => {
            const tx = await marketMakerStake.connect(owner).unStake(1);
            const receipt = await tx.wait();
            console.log("receipt.transactionHash:",receipt.transactionHash);
            
        });
        it("the balance after unStake",async () => {
            const afterUsdtBalance = await usdt.balanceOf(owner.address);
            const afterContractBalance = await usdt.balanceOf(marketMakerStake.address);
            console.log("afterUsdtBalance:",afterUsdtBalance);
            console.log("afterContractBalance:",afterContractBalance);
        });
    });

    describe("reStake",() => {
        beforeEach(async () => {

        });
        it("the balance after reStake",async () => {

        });
    });


});



/**
 * 
npx hardhat test ./test/node/MarketMakerStake.test.ts --network pijstestnet

*/