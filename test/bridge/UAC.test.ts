import { expect } from "chai";
import { ethers, upgrades } from "hardhat";
import { network } from "hardhat";
import {UAC,TestERC20} from "../../typechain-types";


describe("test UAC switch",() => {
    let owner: any;
    let feeReceiver:any;
    let user1: any;
    let user2: any;
    let user3: any;
    let uac:any;
    beforeEach(async () => {
        [owner,feeReceiver,user1,user2,user3] = await ethers.getSigners();
        let uac_addres = "0xe15B602eF891D45251FF749BE97db6a983CdE175";
        uac = (
            await ethers.getContractAt("UAC",uac_addres)
        ) as UAC;
        const tx2 = await uac.connect(owner).updateTradingEnabled(true);
        await tx2.wait();
        // 分别mint给 user1,user2 100eth
        const tx0 = await uac.connect(owner).mint(owner.address,ethers.utils.parseEther("100"));
        await tx0.wait();
        const tx = await uac.connect(owner).mint(user1.address,ethers.utils.parseEther("100"));
        await tx.wait();
        const tx1 = await uac.connect(owner).mint(user2.address,ethers.utils.parseEther("100"));
        await tx1.wait();
        const ownerbalance = await uac.balanceOf(owner.address);
        const user1balance = await uac.balanceOf(user1.address);
        const user2balance = await uac.balanceOf(user2.address);
        console.log("balance of owner:",ownerbalance);
        console.log("balance of user1:",user1balance);
        console.log("balance of user2:",user2balance);
        
    });
    describe("tradingAllowed is true",() => {
            it("can transfer",async () => {
                const beforeTransferToUser1Balance = await uac.balanceOf(user2.address);
                console.log("beforeTransferToUser1Balance:",beforeTransferToUser1Balance);
                const tx = await uac.connect(owner).transfer(user2.address,ethers.utils.parseEther("10"));
                await tx.wait();
                const afterTransferToUser1Balance = await uac.balanceOf(user2.address);
                console.log("afterTransferToUser1Balance:",afterTransferToUser1Balance);
                expect(beforeTransferToUser1Balance.add(ethers.utils.parseEther("10"))).to.equal(afterTransferToUser1Balance);

            });
        }
    );

    describe("tradingAllowed is close",() => {
        beforeEach(async () => {
            const beforeTradingEnabled = await uac.connect(owner).getTradingEnabled();
            console.log("beforeTradingEnabled:",beforeTradingEnabled);
            const tx = await uac.connect(owner).updateTradingEnabled(false);
            await tx.wait();
            const afterTradingEnabled = await uac.connect(owner).getTradingEnabled();
            console.log("afterTradingEnabled:",afterTradingEnabled);
            const tx1 = await uac.connect(owner).updateWhitelist(owner.address,true);
            await tx1.wait();
        });
        it("owner can transfer",async () => {
            const beforeTransferToUser1Balance = await uac.balanceOf(user2.address);
            console.log("beforeTransferToUser1Balance:",beforeTransferToUser1Balance);
            const tx = await uac.connect(owner).transfer(user2.address,ethers.utils.parseEther("10"));
            await tx.wait();
            const afterTransferToUser1Balance = await uac.balanceOf(user2.address);
            console.log("afterTransferToUser1Balance:",afterTransferToUser1Balance);
            expect(beforeTransferToUser1Balance.add(ethers.utils.parseEther("10"))).to.equal(afterTransferToUser1Balance);
        });
        it("user1 can not  transfer",async () => {
            const beforeTransferToUser1Balance = await uac.balanceOf(user2.address);
            console.log("beforeTransferToUser1Balance:",beforeTransferToUser1Balance);
            try {
                const tx = await uac.connect(user1).transfer(user2.address,ethers.utils.parseEther("10"));
                await tx.wait();
            } catch (error) {
                console.log(error);
            }
            
            const afterTransferToUser1Balance = await uac.balanceOf(user2.address);
            console.log("afterTransferToUser1Balance:",afterTransferToUser1Balance);
            
        });

    });


});

/**
 * 
npx hardhat test ./test/bridge/UAC.test.ts --network pijstestnet
 */