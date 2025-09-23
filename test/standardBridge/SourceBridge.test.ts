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
        // const erc20Factory = await ethers.getContractFactory("TestERC20UNI");
        // t1 = await erc20Factory.deploy(owner.address,owner.address);
        // await t1.deployed();

        t1 = await ethers.getContractAt("TestERC20UNI","0x287f7440d14DC327e558E54E2F22309DC009ec78");

        console.log("T1 address is :",t1.address);

        // deploy SourceBridge
        const sourceBridgeFactory = await ethers.getContractFactory("SourceBridge");
        const args = [feeReceiver_address,signer_address,operator_address,feePercentage];
        // sourceBridge =  await upgrades.deployProxy(sourceBridgeFactory,args,{kind:'uups'}) as SourceBridge;
        sourceBridge = await upgrades.upgradeProxy('0x6dE18E9ca74F35AF295cb6639624f37aECAd3679', sourceBridgeFactory, { kind: 'uups' }) as SourceBridge;
        await sourceBridge.deployed();

        // sourceBridge = await ethers.getContractAt("SourceBridge","0x6dE18E9ca74F35AF295cb6639624f37aECAd3679");
        console.log("SourceBridge address is :",sourceBridge.address);

        // mint erc20
        // const tx = await t1.connect(owner).mint(owner.address,ethers.utils.parseEther("10000"));
        // await tx.wait();

    });

    // describe("test desposit ETH",()=> {
    //     let balanceOfTheContractbeforeDeposite:any;
    //     beforeEach(async () => {
    //         balanceOfTheContractbeforeDeposite = await ethers.provider.getBalance(sourceBridge.address);
    //         console.log("balanceOfTheContractbeforeDeposite:",balanceOfTheContractbeforeDeposite);
    //         var params = {
    //             userAddr:owner.address,
    //             receiver:sourceBridge.address,
    //             amount:ethers.utils.parseEther("1"),
    //             orderId:2,
    //             chainId:(await ethers.provider.getNetwork()).chainId
    //         }
    //         const types = {
    //             Permit: [
    //                 { name: "userAddr", type: "address" },
    //                 { name: "receiver", type: "address" },
    //                 { name: "amount", type: "uint256" },
    //                 { name: "orderId", type: "uint256" },
    //                 { name: "chainId", type: "uint256" },
    //             ],
    //         };
    //         const domain = {
    //             name: "SourceBridge",
    //             version: "1",
    //             chainId: (await ethers.provider.getNetwork()).chainId,
    //             verifyingContract: sourceBridge.address,
    //         };
    //         const signature = await owner._signTypedData(domain, types, params);
    //         const data = ethers.utils.defaultAbiCoder.encode(
    //             [
    //                "address",
    //                "address",
    //                "uint256",
    //                "uint256", 
    //                "uint256",
    //                "bytes"
    //             ],[
    //                 params.userAddr,
    //                 params.receiver,
    //                 params.amount,
    //                 params.orderId,
    //                 params.chainId,
    //                 signature
    //             ]
    //         );
    //         const tx = await sourceBridge.depositeETH(data,{
    //             value: ethers.utils.parseEther("1"), 
    //             gasLimit: 1_000_000,
    //         });
    //         const recipient = await tx.wait();
    //         // console.log(recipient);
    //     });
    //     it("The balance is correct",async () => {
    //         const balanceOfTheContractAfterDeposite = await ethers.provider.getBalance(sourceBridge.address);
    //         console.log("balanceOfTheContractAfterDeposite:",balanceOfTheContractAfterDeposite);
    //         expect(balanceOfTheContractAfterDeposite).to.eq(ethers.utils.parseEther("1").add(balanceOfTheContractbeforeDeposite));
    //     });

    // });

    // describe("Test deposite ERC20",() => {
    //     let balanceOfERC20ContractBeforeDeposit:any;
    //     let balanceOfERC20UserBeforeDeposit:any;
    //     beforeEach(async () => {
    //         balanceOfERC20ContractBeforeDeposit = await t1.balanceOf(sourceBridge.address);
    //         balanceOfERC20UserBeforeDeposit = await t1.balanceOf(owner.address);
    //         console.log("balanceOfERC20ContractBeforeDeposit:",balanceOfERC20ContractBeforeDeposit);
    //         console.log("balanceOfERC20UserBeforeDeposit:",balanceOfERC20UserBeforeDeposit);
    //         var params = {
    //             userAddr:owner.address,
    //             tokenAddr:t1.address,
    //             receiver:sourceBridge.address,
    //             amount:ethers.utils.parseEther("100"),
    //             orderId:4,
    //             chainId:(await ethers.provider.getNetwork()).chainId
    //         }
    //         const types = {
    //             Permit: [
    //                 { name: "userAddr", type: "address" },
    //                 { name: "tokenAddr", type: "address" },
    //                 { name: "receiver", type: "address" },
    //                 { name: "amount", type: "uint256" },
    //                 { name: "orderId", type: "uint256" },
    //                 { name: "chainId", type: "uint256" },
    //             ],
    //         }
    //         const domain = {
    //             name: "SourceBridge",
    //             version: "1",
    //             chainId: (await ethers.provider.getNetwork()).chainId,
    //             verifyingContract: sourceBridge.address,
    //         };
    //         const signature = await owner._signTypedData(domain, types, params);
    //         const data = ethers.utils.defaultAbiCoder.encode(
    //             [
    //                "address",
    //                "address",
    //                "address",
    //                "uint256",
    //                "uint256", 
    //                "uint256",
    //                "bytes"
    //             ],[
    //                 params.userAddr,
    //                 params.tokenAddr,
    //                 params.receiver,
    //                 params.amount,
    //                 params.orderId,
    //                 params.chainId,
    //                 signature
    //             ]
    //         );
    //         const tx1 = await t1.approve(sourceBridge.address,ethers.utils.parseEther("1000"));
    //         await tx1.wait();
    //         const tx = await sourceBridge.connect(owner).depositeERC20(data,{
    //              gasLimit: 1_000_000,
    //         });
    //         const receipent = await tx.wait();

    //         // console.log("receipent:",receipent);

    //     });

    //     it("The balance of erc20 is corrent",async () => {
    //         const balanceOfERC20ContractAfterDeposit = await t1.balanceOf(sourceBridge.address);
    //         const balanceOfERC20UserAfterDeposit = await t1.balanceOf(owner.address);
    //         console.log("balanceOfERC20ContractAfterDeposit:",balanceOfERC20ContractAfterDeposit);
    //         console.log("balanceOfERC20UserAfterDeposit:",balanceOfERC20UserAfterDeposit);
    //         expect(balanceOfERC20ContractAfterDeposit).to.equal(balanceOfERC20ContractBeforeDeposit.add(ethers.utils.parseEther("100")));
    //         expect(balanceOfERC20UserAfterDeposit).to.equal(balanceOfERC20UserBeforeDeposit.sub(ethers.utils.parseEther("100")));
    //     });
    // });

    // describe("test withdraw eth",() => {
    //     let beforeWithdrawETHTheBalanceOfContract:any;
    //     let beforeWithdrawETHTheBanlanceOfUser:any;
    //     beforeEach(async () => {
    //         beforeWithdrawETHTheBalanceOfContract = await ethers.provider.getBalance(sourceBridge.address);
    //         beforeWithdrawETHTheBanlanceOfUser = await ethers.provider.getBalance(owner.address);
    //         console.log("beforeWithdrawETHTheBalanceOfContract:",beforeWithdrawETHTheBalanceOfContract);
    //         console.log("beforeWithdrawETHTheBanlanceOfUser:",beforeWithdrawETHTheBanlanceOfUser);
    //         let params = {
    //             caller:user1.address,
    //             amount:ethers.utils.parseEther("1"),
    //             userAddr:owner.address,
    //             orderId:4,
    //             chainId:(await ethers.provider.getNetwork()).chainId
    //         }
    //         const types = {
    //             Permit: [
    //                 { name: "caller", type: "address" },
    //                 { name: "amount", type: "uint256" },
    //                 { name: "userAddr", type: "address" },
    //                 { name: "orderId", type: "uint256" },
    //                 { name: "chainId", type: "uint256" },
    //             ],
    //         }
    //         const domain = {
    //             name: "SourceBridge",
    //             version: "1",
    //             chainId: (await ethers.provider.getNetwork()).chainId,
    //             verifyingContract: sourceBridge.address,
    //         };
    //         const signature = await owner._signTypedData(domain, types, params);
    //         const data = ethers.utils.defaultAbiCoder.encode(
    //             [
    //                "address",
    //                "uint256",
    //                "address",
    //                "uint256",
    //                "uint256", 
    //                "bytes"
    //             ],[
    //                 params.caller,
    //                 params.amount,
    //                 params.userAddr,
    //                 params.orderId,
    //                 params.chainId,
    //                 signature
    //             ]
    //         );
    //         const tx = await sourceBridge.connect(user1).withdrawETH(data,{
    //              gasLimit: 1_000_000,
    //         });
    //         const recipent = await tx.wait();



            
    //     });
    //     it("The balance of eth is corrent",async () => {
    //         const afterWithdrawETHBalanceofContract = await ethers.provider.getBalance(sourceBridge.address);
    //         const afterWithdrawETHBanlanceofUser = await ethers.provider.getBalance(owner.address);
    //         console.log("afterWithdrawETHBalanceofContract:",afterWithdrawETHBalanceofContract);
    //         console.log("afterWithdrawETHBanlanceofUser:",afterWithdrawETHBanlanceofUser);
    //         console.log("the contract subed:",ethers.utils.parseEther(beforeWithdrawETHTheBalanceOfContract.sub(afterWithdrawETHBalanceofContract).toString()));
    //         console.log("the owner added:",ethers.utils.parseEther(afterWithdrawETHBanlanceofUser.sub(beforeWithdrawETHTheBanlanceOfUser).toString()));


    //     });
    // });

    describe("test withdraw erc20",() => {
        let beforeWithdrawERC20BanlanceOfContract:any;
        let beforeWithdrawERC20BanlanceOfUser:any;
        beforeEach(async () => {
            beforeWithdrawERC20BanlanceOfContract = await t1.balanceOf(sourceBridge.address);
            beforeWithdrawERC20BanlanceOfUser = await t1.balanceOf(owner.address);
            console.log("beforeWithdrawERC20BanlanceOfContract:",beforeWithdrawERC20BanlanceOfContract);
            console.log("beforeWithdrawERC20BanlanceOfUser:",beforeWithdrawERC20BanlanceOfUser);
            let params = {
                caller:user1.address,
                tokenAddr:t1.address,
                amount:ethers.utils.parseEther("10"),
                userAddr:owner.address,
                orderId:5,
                chainId:(await ethers.provider.getNetwork()).chainId
            } 
            const types = {
                Permit: [
                    { name: "caller", type: "address" },
                    { name: "tokenAddr", type: "address"},
                    { name: "amount", type: "uint256" },
                    { name: "userAddr", type: "address" },
                    { name: "orderId", type: "uint256" },
                    { name: "chainId", type: "uint256" },
                ],
            }
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
                   "address",
                   "uint256",
                   "uint256", 
                   "bytes"
                ],[
                    params.caller,
                    params.tokenAddr,
                    params.amount,
                    params.userAddr,
                    params.orderId,
                    params.chainId,
                    signature
                ]
            );
            const tx = await sourceBridge.connect(user1).withdrawERC20(data,{
                 gasLimit: 1_000_000,
            });
            const recipent = await tx.wait();
            console.log(recipent);

        });

        it("The balance of erc20 is correct",async () => {
            const afterWithdrawERC20BanlanceOfContract = await t1.balanceOf(sourceBridge.address);
            const afterWithdrawERC20BanlanceOfUser = await t1.balanceOf(owner.address);
            console.log("afterWithdrawERC20BanlanceOfContract:",afterWithdrawERC20BanlanceOfContract);
            console.log("afterWithdrawERC20BanlanceOfUser:",afterWithdrawERC20BanlanceOfUser);

            console.log("the contract erc20 subed:",ethers.utils.parseEther(beforeWithdrawERC20BanlanceOfContract.sub(afterWithdrawERC20BanlanceOfContract).toString()));
            console.log("the user erc20 subed:",ethers.utils.parseEther(afterWithdrawERC20BanlanceOfUser.sub(beforeWithdrawERC20BanlanceOfUser).toString()));

        });
    });


});

/**
 npx hardhat test ./test/standardBridge/SourceBridge.test.ts --network ganache
 */