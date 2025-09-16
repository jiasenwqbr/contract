import { expect } from "chai";
import { ethers, upgrades } from "hardhat";
import { UAC,UAGToken,StakingUAG } from "../../typechain-types";
import { network } from "hardhat";

describe("StakingUAG",() => {
    let owner:any;
    let user1:any;
    let user2:any;
    let user3:any;
    let uac:UAC;
    let uag:UAGToken;
    let stakingUAG:StakingUAG;
    let uag_address:any;
    let uac_address:any;
    let usdtAddress:any;
    let feeAddress:any;
    const stakeAmountMin = ethers.utils.parseEther("10");
    const stakeAmountMax= ethers.utils.parseEther("1000");
    const withdrawalFeePersentage = 50;

      
    beforeEach(async () => {
        [owner,user1, user2,user3] = await ethers.getSigners();
        uac_address = "0xe15B602eF891D45251FF749BE97db6a983CdE175";
        uag_address = "0xc9Ee4524690631FF44f3e7104bF1d08E5c119f1b";
        usdtAddress = "0x3F00C9dd4F081D7b6b758555c621FbEb09d519FD";
        feeAddress = owner.address;
        // deploy uac
        uac = await ethers.getContractAt("UAC",uac_address) as UAC;
        // deploy uag
        uag = await ethers.getContractAt("UAG",uag_address) as UAGToken;
        // deploy StakingUAG
        // stakingUAG = await ethers.getContractAt("StakingUAG","0x327303DB1E5a36Bb34c656c40c50E5020F4B7B53") as StakingUAG;
        const stakingUAGFactory = await ethers.getContractFactory('StakingUAG');
        const args = [owner.address,uag_address,uac_address,feeAddress,stakeAmountMin,stakeAmountMax,withdrawalFeePersentage];
        // stakingUAG =  (await upgrades.deployProxy(stakingUAGFactory,args,{kind:'uups'})) as StakingUAG;
        stakingUAG = await upgrades.upgradeProxy('0x037b9D7eebE5185D2e0399C5AC628606a4089009', stakingUAGFactory, { kind: 'uups' }) as StakingUAG;
        await stakingUAG.deployed();
        // stakingUAG = await ethers.getContractAt("StakingUAG","0x037b9D7eebE5185D2e0399C5AC628606a4089009") as StakingUAG;

        // 0x477a92853E04655d12A8AE3c70eC8fF96Da4545B
        console.log("StakingUAG address is:",stakingUAG.address);
    });

    describe("stakingUAG stakeUAG",() => {
        beforeEach(async () => {
            var params = {
                orderId:8,
                userAddress:owner.address,
                tokenAddress:uag_address,
                amount:ethers.utils.parseEther("10"),
                burnAmount:ethers.utils.parseEther("1"),
                energyValue:1000
            };
            const types = {
                Permit: [
                    { name: "orderId", type: "uint256" },
                    { name: "userAddress", type: "address" },
                    { name: "tokenAddress", type: "address" },
                    { name: "amount", type: "uint256" },
                    { name: "burnAmount", type: "uint256" },
                    { name: "energyValue", type: "uint256" },
                ],
            };
            const domain = {
                name: "StakingUAG",
                version: "1",
                chainId: (await ethers.provider.getNetwork()).chainId,
                verifyingContract: stakingUAG.address,
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
                   "bytes"
                ],[
                    params.orderId,
                    params.userAddress,
                    params.tokenAddress,
                    params.amount,
                    params.burnAmount,
                    params.energyValue,
                    signature
                ]
            );

            // balance of contract
            const contractBalanceOfUAG = await uag.balanceOf(stakingUAG.address);
            const ownerBalanceOfUAG = await uag.balanceOf(owner.address);

            console.log("contractBalanceOfUAG:",contractBalanceOfUAG);
            console.log("ownerBalanceOfUAG:",ownerBalanceOfUAG);

            const tx1 = await uag.connect(owner).approve(stakingUAG.address,ethers.utils.parseEther("100"));
            await tx1.wait();
            const allowance = await uac.allowance(owner.address, stakingUAG.address);
            console.log("Current allowance:", allowance.toString());
            const tx = await stakingUAG.connect(owner).stakeUAG(data,{
                gasLimit: 1_000_000,
            });
            const receipt = await tx.wait();
            console.log("receipt.transactionHash:",receipt.transactionHash);

        });
        it("after tx balanceof ",async () => {
            const contractBalanceOfUAG = await uag.balanceOf(stakingUAG.address);
            const ownerBalanceOfUAG = await uag.balanceOf(owner.address);

            console.log("after tx balanceof contractBalanceOfUAG:",contractBalanceOfUAG);
            console.log("after tx balanceof ownerBalanceOfUAG:",ownerBalanceOfUAG);
        });
    });

    describe("test unStake",() => {
        let beforeBalanceOfOwner:any;
        let beforeBalanceOfContract:any;
        beforeEach(async () => {
            var params = {
                orderId:8,
                userAddress:owner.address,
                tokenAddress:uag_address,
                amount:ethers.utils.parseEther("10")
            };
            const types = {
                Permit: [
                    { name: "orderId", type: "uint256" },
                    { name: "userAddress", type: "address" },
                    { name: "tokenAddress", type: "address" },
                    { name: "amount", type: "uint256" }
                ],
            };
            const domain = {
                name: "StakingUAG",
                version: "1",
                chainId: (await ethers.provider.getNetwork()).chainId,
                verifyingContract: stakingUAG.address,
            };
            const signature = await owner._signTypedData(domain, types, params);
            const data = ethers.utils.defaultAbiCoder.encode(
                [
                   "uint256",
                   "address",
                   "address",
                   "uint256", 
                   "bytes"
                ],[
                    params.orderId,
                    params.userAddress,
                    params.tokenAddress,
                    params.amount,
                    signature
                ]
            );

            beforeBalanceOfContract = await uag.balanceOf(stakingUAG.address);
            beforeBalanceOfOwner = await uag.balanceOf(owner.address);
            console.log("beforeBalanceOfContract:",beforeBalanceOfContract);
            console.log("beforeBalanceOfOwner:",beforeBalanceOfOwner);
            const tx = await stakingUAG.connect(owner).unStake(data,{
                gasLimit: 1_000_000,
            });
            const receipt = await tx.wait();
            console.log("receipt.transactionHash:",receipt.transactionHash);
        });

        it("unstake balance of ",async () => {
            const afterBalanceOfContract = await uag.balanceOf(stakingUAG.address);
            const afterBalanceOfOwner = await uag.balanceOf(owner.address);
            console.log("afterBalanceOfContract:",afterBalanceOfContract);
            console.log("afterBalanceOfOwner:",afterBalanceOfOwner);
        });
    });
});

/**
 * 

npx hardhat test ./test/node/StakingUAG.test.ts --network pijstestnet

*/