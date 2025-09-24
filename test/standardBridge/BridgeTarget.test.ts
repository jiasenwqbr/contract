import { expect } from "chai";
import { ethers,upgrades,network } from "hardhat";
import { SourceBridge,TestERC20UNI,BridgeTarget } from "../../typechain-types";

describe("BridgeTarget test",() => {
    let feeReceiver_address:any;
    let operator_address:any;
    let signer_address:any;
    let feePercentage = 50;
    let t1:TestERC20UNI;
    let sourceBridge:SourceBridge;
    let owner:any;
    let user1:any;
    let user2:any;
    let user3:any;
    let bridgeTarget:BridgeTarget;
    beforeEach(async () => {
        [owner,user1,user2,user3] = await ethers.getSigners();
        feeReceiver_address = user3.address;
        operator_address = user1.address;
        signer_address = owner.address;


        t1 = await ethers.getContractAt("TestERC20UNI","0x287f7440d14DC327e558E54E2F22309DC009ec78");
        console.log("T1 address is :",t1.address);
        

        const args = [operator_address,feeReceiver_address,feePercentage,signer_address];
        const bridgeTargetFactory = await  ethers.getContractFactory("BridgeTarget");
        // bridgeTarget =  await upgrades.deployProxy(bridgeTargetFactory,args,{kind:'uups'}) as BridgeTarget;
        //bridgeTarget = await upgrades.upgradeProxy('0x7257d547c5664599Ed3Fb5F6D74ab3a4Bbe90a33', bridgeTargetFactory, { kind: 'uups' }) as BridgeTarget;
        //await bridgeTarget.deployed();
        bridgeTarget = await ethers.getContractAt("BridgeTarget","0x7257d547c5664599Ed3Fb5F6D74ab3a4Bbe90a33") as BridgeTarget;
        console.log("BridgeTarget address is :",bridgeTarget.address);
        // const tx1 = await t1.grantRole(await t1.MINTER_ROLE(),bridgeTarget.address);
        // await tx1.wait();
    });


    describe("test mintToken",() => {
        let theBalanceOfUser2BeforeMintToken:any;
        let theBalanceOfReceiverBeforeMintToken:any;
        beforeEach(async () => {
            theBalanceOfUser2BeforeMintToken = await t1.balanceOf(user2.address);
            theBalanceOfReceiverBeforeMintToken = await t1.balanceOf(user3.address);
            console.log("theBalanceOfUser2BeforeMintToken:",theBalanceOfUser2BeforeMintToken);
            console.log("theBalanceOfReceiverBeforeMintToken:",theBalanceOfReceiverBeforeMintToken);
            let params = {
                caller:operator_address,
                to:user2.address,
                amount:ethers.utils.parseEther("10"),
                token:t1.address,
                orderId:5
            } 
            const types = {
                Permit: [
                    { name: "caller", type: "address" },
                    { name: "to", type: "address"},
                    { name: "amount", type: "uint256" },
                    { name: "token", type: "address" },
                    { name: "orderId", type: "uint256" }
                ],
            }
            const domain = {
                name: "BridgeTarget",
                version: "1",
                chainId: (await ethers.provider.getNetwork()).chainId,
                verifyingContract: bridgeTarget.address,
            };
            const signature = await owner._signTypedData(domain, types, params);
            const data = ethers.utils.defaultAbiCoder.encode(
                [
                   "address",
                   "address",
                   "uint256",
                   "address",
                   "uint256",
                   "bytes"
                ],[
                    params.caller,
                    params.to,
                    params.amount,
                    params.token,
                    params.orderId,
                    signature
                ]
            );

            const tx = await bridgeTarget.connect(user1).mintToken(data,{
                gasLimit: 1_000_000,
            });
            const recipient = await tx.wait();



        });
        it("the banlance is correct",async () => {
            const theBalanceOfUser2AfterMintToken = await t1.balanceOf(user2.address);
            const theBalanceOfReceiverAfterMintToken = await t1.balanceOf(user3.address);
            console.log("theBalanceOfUser2AfterMintToken:",ethers.utils.formatEther(theBalanceOfUser2AfterMintToken));
            console.log("theBalanceOfReceiverAfterMintToken:",ethers.utils.formatEther(theBalanceOfReceiverAfterMintToken));
            
            
        });
    });

    describe("test tokenBurned",() => {
        let theBalanceOfUser2BeforeBurnToken:any;
        let theBalanceOfReceiverBeforeBurnToken:any;
        beforeEach(async () => {
            theBalanceOfUser2BeforeBurnToken = await t1.balanceOf(user2.address);
            theBalanceOfReceiverBeforeBurnToken = await t1.balanceOf(user3.address);
            console.log("theBalanceOfUser2BeforeBurnToken:",ethers.utils.formatEther(theBalanceOfUser2BeforeBurnToken));
            console.log("theBalanceOfReceiverBeforeBurnToken:",ethers.utils.formatEther(theBalanceOfReceiverBeforeBurnToken));
            let params = {
                caller:user2.address,
                amount:ethers.utils.parseEther("10"),
                token:t1.address,
                orderId:1
            }
            const types = {
                Permit: [
                    { name: "caller", type: "address" },
                    { name: "amount", type: "uint256" },
                    { name: "token", type: "address" },
                    { name: "orderId", type: "uint256" }
                ],
            }
            const domain = {
                name: "BridgeTarget",
                version: "1",
                chainId: (await ethers.provider.getNetwork()).chainId,
                verifyingContract: bridgeTarget.address,
            };
            const signature = await owner._signTypedData(domain, types, params);
            const data = ethers.utils.defaultAbiCoder.encode(
                [
                   "address",
                   "uint256",
                   "address",
                   "uint256",
                   "bytes"
                ],[
                    params.caller,
                    params.amount,
                    params.token,
                    params.orderId,
                    signature
                ]
            );
            const tx2 = await t1.connect(user2).approve(bridgeTarget.address,ethers.utils.parseEther("20"));
            await tx2.wait();
            const tx = await bridgeTarget.connect(user2).tokenBurned(data,{
                 gasLimit: 1_000_000,
            });
            const receipent = await tx.wait();




        });
        it("the balance is correct",async () => {
            const theBalanceOfUser2AfterBurnToken = await t1.balanceOf(user2.address);
            const theBalanceOfReceiverAfterBurnToken = await t1.balanceOf(user3.address);
            console.log("theBalanceOfUser2AfterBurnToken:",ethers.utils.formatEther(theBalanceOfUser2AfterBurnToken));
            console.log("theBalanceOfReceiverAfterBurnToken:",ethers.utils.formatEther(theBalanceOfReceiverAfterBurnToken));
            

        });
    });
});


/**
 npx hardhat test ./test/standardBridge/BridgeTarget.test.ts --network ganache
 */