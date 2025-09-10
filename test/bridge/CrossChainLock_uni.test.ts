import { expect } from "chai";
import { ethers, upgrades } from "hardhat";
import { network } from "hardhat";
import {CrossChainLockTest} from "../../typechain-types";

describe("CrossChainLock",()=> {
    let crossChainLock:CrossChainLockTest;
    let owner:any;
    let feeReceiver:any;
    let user1: any;
    let user2: any;
    let user3: any;
    let token:any;
    let feeDenominator = 10000;
    let feePercent = 500;
    beforeEach(async () => {
        [owner] = await ethers.getSigners();
        
        crossChainLock = (
            await ethers.getContractAt("CrossChainLockTest","0x3D436e3503B40a2c73D0EA70ab407405aDaf13d5")
        ) as CrossChainLockTest;
    });

  

    describe("depositeUNI",() => {
        it("deposite UNI value should be correct", async () => {
            var params = {
                userAddr:owner.address,
                receiver:crossChainLock.address,
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
                name: "UnionBridgeSource",
                version: "1",
                chainId: (await ethers.provider.getNetwork()).chainId,
                verifyingContract: crossChainLock.address,
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
                    1,
                    params.orderId,
                    params.chainId,
                    signature
                ]
            );

          console.log("data:",data);
            const tx = await crossChainLock.connect(owner).depositeUNI(data,{
                value: ethers.utils.parseEther("1"), 
                gasLimit: 1_000_000,
            });
            await tx.wait();
           
        });
    });

});

/**
 npx hardhat test ./test/bridge/CrossChainLock_uni.test.ts --network uac
 */