import { expect } from "chai";
import { ethers,upgrades,network } from "hardhat";
import { SourceBridge,TestERC20UNI } from "../../typechain-types";

describe("SourceBridge test",() => {
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

    beforeEach(async () => {
        [owner,user1,user2,user3] = await ethers.getSigners();
        feeReceiver_address = user1.address;
        operator_address = user1.address;
        signer_address = owner.address;
        // deploy erc20
        const erc20Factory = await ethers.getContractFactory("TestERC20UNI");
        t1 = await erc20Factory.deploy(owner.address,owner.address);
        await t1.deployed();

        console.log("T1 address is :",t1.address);

        // deploy SourceBridge
        const sourceBridgeFactory = await ethers.getContractFactory("SourceBridge");
        const args = [feeReceiver_address,signer_address,operator_address,feePercentage];
        sourceBridge =  await upgrades.deployProxy(sourceBridgeFactory,args,{kind:'uups'}) as SourceBridge;
        await sourceBridge.deployed();

        // mint erc20
        const tx = await t1.connect(owner).mint(owner.address,ethers.utils.parseEther("10000"));
        await tx.wait();

    });

    describe("test desposit ETH",()=> {
        beforeEach(async () => {
            var params = {
                userAddr:owner.address,
                receiver:sourceBridge.address,
                amount:ethers.utils.parseEther("1"),
                orderId:1,
                chainId:(await ethers.provider.getNetwork()).chainId
            }
            const types = {
                Permit: [
                    { name: "userAddr", type: "address" },
                    { name: "receiver", type: "address" },
                    { name: "amount", type: "uint256" },
                    { name: "orderId", type: "uint256" },
                    { name: "chainId", type: "uint256" },
                ],
            };
            const domain = {
                name: "SourceBridge",
                version: "1",
                chainId: (await ethers.provider.getNetwork()).chainId,
                verifyingContract: sourceBridge.address,
            };
            const signature = await owner._signTypedData(domain, types, params);
            const data = ethers.utils.defaultAbiCoder.encode(
                [
                   "address",
                   "address",
                   "uint256",
                   "uint256", 
                   "uint256", 
                   "uint256",
                   "bytes"
                ],[
                    params.userAddr,
                    params.receiver,
                    params.amount,
                    params.orderId,
                    params.chainId,
                    signature
                ]
            );
            const tx = await sourceBridge.depositeETH(data,{
                value: ethers.utils.parseEther("1"), 
                gasLimit: 1_000_000,
            });
            const recipient = await tx.wait();
            console.log(recipient);
        });
        it("The balance is correct",async () => {
            const balanceOfTheContractAfterDeposite = await ethers.provider.getBalance(sourceBridge.address);
            console.log("balanceOfTheContractAfterDeposite:",balanceOfTheContractAfterDeposite);
            expect(balanceOfTheContractAfterDeposite).to.eq(ethers.utils.parseEther("1"));
        });

    });

    describe("Test deposite ERC20",() => {
        beforeEach(async () => {
            
        });

        it("The balance of erc20 is corrent",async () => {

        });
    });

    describe("test withdraw eth",() => {
        beforeEach(async () => {

        });
        it("The balance of eth is corrent",async () => {

        });
    });

    describe("test withdraw erc20",() => {
        beforeEach(async () => {

        });

        it("The balance of erc20 is correct",async () => {

        });
    });


});

/**
 npx hardhat test ./test/standardBridge/SourceBridge.test.ts --network ganache
 */