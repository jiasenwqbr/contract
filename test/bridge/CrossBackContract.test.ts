import { expect } from "chai";
import { ethers,upgrades,network } from "hardhat";
import { CrossBackContract,UACERC20 } from "../../typechain-types";

describe("CrossBackContract unit test",() => {
    let uac:UACERC20;
    let crossBackContract: CrossBackContract;
    let owner:any;
    let operator:any;
    let signer:any;
    let admin:any;
    let feeReceiver:any;
    beforeEach(async () => {
        [owner,feeReceiver] = await ethers.getSigners();
        operator = owner;
        signer = owner;
        admin = owner;
        // deploy UAC
        const uacErc20Factory = await ethers.getContractFactory("UACERC20");
        uac = (
            await upgrades.deployProxy(uacErc20Factory,['UAC','UAC',admin.address,operator.address,feeReceiver.address,50,signer.address],{initializer:"initialize"})
        ) as UACERC20;
        await uac.deployed();
        const tx = await uac.connect(owner).mint(owner.address,ethers.utils.parseEther("1000"));
        tx.wait();
        const burnFromSupported = await uac.supportsInterface("0x79cc6790"); // burnFrom的interfaceId
        console.log("Supports burnFrom:", burnFromSupported);
        // deploy CrossBackContract
        const crossBackContractFactory = await ethers.getContractFactory("CrossBackContract");
        crossBackContract = (
            await upgrades.deployProxy(crossBackContractFactory,[operator.address,signer.address,admin.address,feeReceiver.address],{initializer:"initialize"})
        ) as CrossBackContract;
        await crossBackContract.deployed();
        const balaceOfOwner = await uac.balanceOf(owner.address);
        console.log("beforeEach the UAC balance of owner is:",balaceOfOwner);
    });

    describe("Test CrossBackContract",() => {
        it("test tokenBurned ,the balance is correct or not ",async () => {
            const params = {
                caller:owner.address,
                receiver:feeReceiver.address,
                tokenAddress:uac.address,
                amount:ethers.utils.parseEther("100"),
                fee:ethers.utils.parseEther("10"),
                orderId:1,
                chainId:(await ethers.provider.getNetwork()).chainId
            };
            // Permit(address caller,address receiver,address tokenAddress,uint256 amount,uint256 fee,uint256 orderId,uint256 chainId)
            const types = {
                Permit: [
                    { name: "caller", type: "address" },
                    { name: "receiver", type: "address" },
                    { name: "tokenAddress", type: "address"},
                    { name: "amount", type: "uint256" },
                    { name: "fee", type: "uint256" },
                    { name: "orderId", type: "uint256" },
                    { name: "chainId", type: "uint256" },
                ],
            };
            const domain = {
                name: "CrossBackContract",
                version: "1",
                chainId: (await ethers.provider.getNetwork()).chainId,
                verifyingContract: crossBackContract.address,
            };
            const signature = await owner._signTypedData(domain, types, params);
            const data = ethers.utils.defaultAbiCoder.encode(
                [
                    "address",
                    "uint256",
                    "uint256",
                    "uint256",
                    "address",
                    "address",
                    "uint256",
                    "uint256",
                    "bytes",
                ],
                [
                    params.caller,
                    params.amount,
                    params.fee,
                    params.orderId,
                    params.receiver,
                    params.tokenAddress,
                    2,
                    params.chainId,
                    signature,
                ]
            );
            const beforeBurnOwnerBalance = await uac.balanceOf(owner.address);
            const beforeBurnReceiverBalance = await uac.balanceOf(feeReceiver.address);
            const beforeContractUACBalance = await uac.balanceOf(uac.address);
            console.log("beforeBurnOwnerBalance:",beforeBurnOwnerBalance);
            console.log("beforeBurnReceiverBalance:",beforeBurnReceiverBalance);
            console.log("beforeContractUACBalance:",beforeContractUACBalance);

            // approve 
            const tx1 = await uac.connect(owner).approve(crossBackContract.address,ethers.utils.parseEther("100"));
            tx1.wait();
            console.log("allowance:", await uac.allowance(owner.address, crossBackContract.address));

            // burn
            const tx = await crossBackContract.connect(owner).tokenBurned(data,{
                 gasLimit: 1_000_000
            });
            tx.wait();


            const afterBurnOwnerBalance = await uac.balanceOf(owner.address);
            const afterBurnReceiverBalance = await uac.balanceOf(feeReceiver.address);
            const afterContractUACBalance = await uac.balanceOf(uac.address);
            console.log("afterBurnOwnerBalance:",afterBurnOwnerBalance);
            console.log("afterBurnReceiverBalance:",afterBurnReceiverBalance);
            console.log("afterContractUACBalance:",afterContractUACBalance);

        });
    });




});

/**
npx hardhat test ./test/bridge/CrossBackContract.test.ts --network ganache
 */