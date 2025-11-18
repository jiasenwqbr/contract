import { expect } from "chai";
import { ethers, upgrades } from "hardhat";
import {TestUSDT,PIJSStakingRewardDistribute,Staking,ValidateNode,ValidateNodeManage} from  "../../typechain-types";
import { network } from "hardhat";
import { BigNumber, Signer } from "ethers";


describe("NodeManage",() => {
    let owner:any;
    let signer:any;
    let validateNode:ValidateNode;
    let validateNodeManage:ValidateNodeManage;
    let usdt:TestUSDT;
    let validateNodeAddress = "0xC845fD732969c90C904186b6D28960Bd935995b6";
    let validateNodeManageAddress = "0xF1aa795e14735248EF251b3c71976AD46309cD64";
    let usdtAddress = "0xb2930010444231dCA259051454b0c1D5d336112E";
    let node:any;
    let receiver:any;
    let buyOrderId;
    let buyNonce: BigNumber;
    let registNonce:BigNumber;
    let agentNode:any;
    let registAgentNonce:BigNumber;
    let renewAgentNonce:BigNumber;
    let stakingAddress = '0xF800c7aD3a92f64455B8838BDe2a173FEE95946e';
    let staking:Staking;
    let validateStakeNonce:BigNumber;
    let agentStakeNonce:BigNumber;
    let client:any;
    let clientStakeNonce:BigNumber;
    let reward:PIJSStakingRewardDistribute;
    let rewardAddress = '0x13843f3bcBeDeFEf77d6ACf63636e9c651a4ed1E';
    let withdrawNonce:BigNumber;

    beforeEach( async () => {
        [owner,signer,node,receiver,agentNode,client] = await ethers.getSigners();
        
        // usdt
        usdt = await ethers.getContractAt("TestUSDT",usdtAddress);
        validateNode = await ethers.getContractAt("ValidateNode",validateNodeAddress);
        validateNodeManage = await ethers.getContractAt("ValidateNodeManage",validateNodeManageAddress);
        staking = await ethers.getContractAt("Staking",stakingAddress);
        reward = await ethers.getContractAt("PIJSStakingRewardDistribute",rewardAddress);

        console.log("node balance of usdt:",ethers.utils.formatEther(await usdt.balanceOf(node.address)) );
        console.log("receiver balance of usdt:",ethers.utils.formatEther(await usdt.balanceOf(receiver.address)));
        console.log("validateNodeManage balance of usdt:",ethers.utils.formatEther(await usdt.balanceOf(validateNodeManageAddress)));
        buyNonce = await validateNodeManage.buyValidateNodeNonces(node.address);
        registNonce = await validateNodeManage.registValidateNodeNonces(owner.address);
        registAgentNonce = await validateNodeManage.registValidateNodeNonces(agentNode.address);
        renewAgentNonce = await validateNodeManage.renewAgentNonces(agentNode.address);
        validateStakeNonce = await staking.validatorStakeNonces(node.address);
        agentStakeNonce = await staking.agentStakeNonces(agentNode.address);
        clientStakeNonce = await staking.clientStakeNonces(client.address);
        withdrawNonce = await reward.withdrawNonces(node.address);
    });

    it("testbuyNode",async () => {
        var params = {
            orderId:buyNonce.add(1),
            // name:'jason',
            purchaseDuration:180 * 24 * 60 * 60,
            tokenAddress:usdtAddress,
            payAmount:ethers.utils.parseEther('100'),
            feeTo:receiver.address,
            expiryDate: Math.floor(Date.now() / 1000) + 180 * 24 * 60 * 60,
            agentAddress:receiver.address,
            nonce:buyNonce
        }

        const types = {
            Permit: [
                { name: "orderId", type: "uint256" },
                // { name: "name", type: "string" },
                { name: "purchaseDuration", type: "uint256" },
                { name: "tokenAddress", type: "address" },
                { name: "payAmount", type: "uint256" },
                { name: "feeTo", type: "address" },
                { name: "expiryDate", type: "uint256" },
                { name: "agentAddress", type: "address" },
                { name: "nonce", type: "uint256" },
            ],
        };
        const domain = {
            name: "NodeManage",
            version: "1",
            chainId: (await ethers.provider.getNetwork()).chainId,
            verifyingContract: validateNodeManageAddress,
        };

        const signature = await owner._signTypedData(domain, types, params);
        const data = ethers.utils.defaultAbiCoder.encode(
            [
                "uint256",
                "string",
                "uint256",
                "address", 
                "uint256", 
                "address",
                "uint256",
                "address",
                "uint256",
                "bytes"
            ],[
                params.orderId,
                "jason",
                params.purchaseDuration,
                params.tokenAddress,
                params.payAmount,
                params.feeTo,
                params.expiryDate,
                params.agentAddress,
                params.nonce,
                signature
            ]
        );

        console.log("node balance of usdt:",ethers.utils.formatEther(await usdt.balanceOf(node.address)) );
        console.log("receiver balance of usdt:",ethers.utils.formatEther(await usdt.balanceOf(receiver.address)));
        const beforeBuyReceiverBalance = await usdt.balanceOf(receiver.address);
        const beforeBuyBuyerBalance = await usdt.balanceOf(node.address);
        const tx0 = await usdt.connect(node).approve(validateNodeManageAddress,ethers.utils.parseEther("100"));
        await tx0.wait();
        const tx = await validateNodeManage.connect(node).buyNode(data);
        await tx.wait();

        console.log("node balance of usdt:",ethers.utils.formatEther(await usdt.balanceOf(node.address)) );
        console.log("receiver balance of usdt:",ethers.utils.formatEther(await usdt.balanceOf(receiver.address)));
        const afterBuyReceiverBalance = await usdt.balanceOf(receiver.address);
        const afterBuyBuyerBalance = await usdt.balanceOf(node.address);

        expect(beforeBuyReceiverBalance.add(params.payAmount)).to.equal(afterBuyReceiverBalance);
        expect(beforeBuyBuyerBalance.sub(params.payAmount)).to.equal(afterBuyBuyerBalance);

    });

    it("registNode",async () => {
        var params = {
            nodeType:1,
            name:'jason',
            nodeAddress:node.address,
            nonce:registNonce
        };

        const tx0 = await validateNodeManage.grantRole(validateNodeManage.OPERATE_ROLE(),owner.address);
        await tx0.wait();

        const tx = await validateNodeManage.connect(owner).registNode(params.nodeType,params.name,params.nonce,params.nodeAddress,{
                 gasLimit: 1_000_000
            });
        await tx.wait();
    });

    it("node info",async () => {
        const validateNodeInfo = await validateNode.getValidatorNodeInfo(node.address);

        console.log("validateNodeInfo:",validateNodeInfo);
    });

    it("test registAgent", async() => {
        var params = {
            orderId:buyNonce.add(1),
            purchaseDuration:180 * 24 * 60 * 60,
            agentAddress:agentNode.address,
            feeTo:receiver.address,
            expiryDate: Math.floor(Date.now() / 1000) + 180 * 24 * 60 * 60,
            payAmount:ethers.utils.parseEther('1'),
            nonce:registAgentNonce
        };

        const types = {
            Permit: [
                { name: "orderId", type: "uint256" },
                // { name: "name", type: "string" },
                { name: "purchaseDuration", type: "uint256" },
                { name: "agentAddress", type: "address" },
                { name: "feeTo", type: "address" },
                { name: "expiryDate", type: "uint256" },
                { name: "payAmount", type: "uint256" },
                { name: "nonce", type: "uint256" },
            ],
        };
        const domain = {
            name: "NodeManage",
            version: "1",
            chainId: (await ethers.provider.getNetwork()).chainId,
            verifyingContract: validateNodeManageAddress,
        };
        const signature = await owner._signTypedData(domain, types, params);
        const data = ethers.utils.defaultAbiCoder.encode(
            [
                "uint256",
                "string",
                "uint256",
                "address", 
                "address", 
                "uint256",
                "uint256",
                "uint256",
                "bytes"
            ],[
                params.orderId,
                "jason",
                params.purchaseDuration,
                params.agentAddress,
                params.feeTo,
                params.expiryDate,
                params.payAmount,
                params.nonce,
                signature
            ]
        );

        const beforeRegistationFeeToBalance = await  ethers.provider.getBalance(params.feeTo);
        const beforeRegistationAgentNodeBalance = await  ethers.provider.getBalance(params.agentAddress);
        console.log("beforeRegistationFeeToBalance:",ethers.utils.formatEther(beforeRegistationFeeToBalance));
        console.log("beforeRegistationAgentNodeBalance:",ethers.utils.formatEther(beforeRegistationAgentNodeBalance));

        const tx = await validateNodeManage.connect(agentNode).registAgent(data,{
            value: ethers.utils.parseEther("1"), 
            gasLimit: 1_000_000,
        });
        await tx.wait();

        const afterRegistationFeeToBalance = await  ethers.provider.getBalance(params.feeTo);
        const afterRegistationAgentNodeBalance = await  ethers.provider.getBalance(params.agentAddress);
        console.log("afterRegistationFeeToBalance:",ethers.utils.formatEther(afterRegistationFeeToBalance));
        console.log("afterRegistationAgentNodeBalance:",ethers.utils.formatEther(afterRegistationAgentNodeBalance));

        expect(beforeRegistationFeeToBalance.add(ethers.utils.parseEther("1"))).to.equal(afterRegistationFeeToBalance);
    });

    it("agent info",async () => {
        const agentNodeInfo = await validateNode.getAgentInfo(agentNode.address);
        console.log("agentNodeInfo:",agentNodeInfo);
    });

    it("test renew agent",async() => {
        var params = {
            orderId:1,
            purchaseDuration:180 * 24 * 60 * 60,
            expiryDate: Math.floor(Date.now() / 1000) + 180 * 24 * 60 * 60,
            agentAddress:agentNode.address,
            payAmount:ethers.utils.parseEther('1'),
            nonce:renewAgentNonce
        };
        const types = {
            Permit: [
                { name: "orderId", type: "uint256" },
                { name: "purchaseDuration", type: "uint256" },
                { name: "expiryDate", type: "uint256" },
                { name: "agentAddress", type: "address" },
                { name: "payAmount", type: "uint256" },
                { name: "nonce", type: "uint256" },
            ],
        };

        const domain = {
            name: "NodeManage",
            version: "1",
            chainId: (await ethers.provider.getNetwork()).chainId,
            verifyingContract: validateNodeManageAddress,
        };
        const signature = await owner._signTypedData(domain, types, params);
        const data = ethers.utils.defaultAbiCoder.encode(
            [
                "uint256",
                "uint256",
                "uint256", 
                "address", 
                "uint256",
                "uint256",
                "bytes"
            ],[
                params.orderId,
                params.purchaseDuration,
                params.expiryDate,
                params.agentAddress,
                params.payAmount,
                params.nonce,
                signature
            ]
        );

        const tx = await validateNodeManage.connect(agentNode).renewAgent(data,{
            value: ethers.utils.parseEther("1"), 
            gasLimit: 1_000_000,
        });
        await tx.wait();



    });


    it("test validiatorStake",async () => {
        var params = {
            orderId:validateStakeNonce.add(1),
            validatorAddress:node.address,
            agentAddress:agentNode.address,
            stakeDuration:180 * 24 * 60 * 60,
            stakeAmount:ethers.utils.parseEther("5"),
            nonce:validateStakeNonce
        };
        const types = {
            Permit: [
                { name: "orderId", type: "uint256" },
                { name: "validatorAddress", type: "address" },
                { name: "agentAddress", type: "address" },
                { name: "stakeDuration", type: "uint256" },
                { name: "stakeAmount", type: "uint256" },
                { name: "nonce", type: "uint256" },
            ],
        };
        const domain = {
            name: "Staking",
            version: "1",
            chainId: (await ethers.provider.getNetwork()).chainId,
            verifyingContract: stakingAddress,
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
                params.validatorAddress,
                params.agentAddress,
                params.stakeDuration,
                params.stakeAmount,
                params.nonce,
                signature
            ]
        );

        const beforeValidatorStakeBalance = await  ethers.provider.getBalance(params.validatorAddress);
        const beforeContractBalance = await  ethers.provider.getBalance(stakingAddress);
        console.log("beforeValidatorStakeBalance:",ethers.utils.formatEther(beforeValidatorStakeBalance));
        console.log("beforeContractBalance:",ethers.utils.formatEther(beforeContractBalance));

        const tx1 = await staking.connect(node).validiatorStake(data,{
            value: ethers.utils.parseEther("5"), 
            gasLimit: 1_000_000,
        });
        await tx1.wait();

        const afterValidatorStakeBalance = await  ethers.provider.getBalance(params.validatorAddress);
        const afterContractBalance = await  ethers.provider.getBalance(stakingAddress);
        console.log("afterValidatorStakeBalance:",ethers.utils.formatEther(afterValidatorStakeBalance));
        console.log("afterContractBalance:",ethers.utils.formatEther(afterContractBalance));

    });

    it("test agentStake",async() => {
        var params = {
            orderId:agentStakeNonce.add(1),
            validatorAddress:node.address,
            agentAddress:agentNode.address,
            stakeDuration:180 * 24 * 60 * 60,
            stakeAmount:ethers.utils.parseEther("5"),
            nonce:agentStakeNonce
        };
        const types = {
            Permit: [
                { name: "orderId", type: "uint256" },
                { name: "validatorAddress", type: "address" },
                { name: "agentAddress", type: "address" },
                { name: "stakeDuration", type: "uint256" },
                { name: "stakeAmount", type: "uint256" },
                { name: "nonce", type: "uint256" },
            ],
        };
        const domain = {
            name: "Staking",
            version: "1",
            chainId: (await ethers.provider.getNetwork()).chainId,
            verifyingContract: stakingAddress,
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
                params.validatorAddress,
                params.agentAddress,
                params.stakeDuration,
                params.stakeAmount,
                params.nonce,
                signature
            ]
        );

        const beforeAgentStakeBalance = await  ethers.provider.getBalance(params.agentAddress);
        const beforeContractBalance = await  ethers.provider.getBalance(stakingAddress);
        console.log("beforeAgentStakeBalance:",ethers.utils.formatEther(beforeAgentStakeBalance));
        console.log("beforeContractBalance:",ethers.utils.formatEther(beforeContractBalance));

        const tx1 = await staking.connect(agentNode).agentStake(data,{
            value: ethers.utils.parseEther("5"), 
            gasLimit: 1_000_000,
        });
        await tx1.wait();

        const afterAgentStakeBalance = await  ethers.provider.getBalance(params.agentAddress);
        const afterContractBalance = await  ethers.provider.getBalance(stakingAddress);
        console.log("afterAgentStakeBalance:",ethers.utils.formatEther(afterAgentStakeBalance));
        console.log("afterContractBalance:",ethers.utils.formatEther(afterContractBalance));
    });

    it("test clientStake",async () => {
         var params = {
            orderId:clientStakeNonce.add(1),
            validatorAddress:node.address,
            agentAddress:agentNode.address,
            clientAddress:client.address,
            stakeDuration:180 * 24 * 60 * 60,
            stakeAmount:ethers.utils.parseEther("5"),
            nonce:clientStakeNonce
        };
        const types = {
            Permit: [
                { name: "orderId", type: "uint256" },
                { name: "validatorAddress", type: "address" },
                { name: "agentAddress", type: "address" },
                { name: "clientAddress", type: "address" },
                { name: "stakeDuration", type: "uint256" },
                { name: "stakeAmount", type: "uint256" },
                { name: "nonce", type: "uint256" },
            ],
        };
        const domain = {
            name: "Staking",
            version: "1",
            chainId: (await ethers.provider.getNetwork()).chainId,
            verifyingContract: stakingAddress,
        };
         const signature = await owner._signTypedData(domain, types, params);
        const data = ethers.utils.defaultAbiCoder.encode(
            [
                "uint256",
                "address",
                "address",
                "address",
                "uint256", 
                "uint256", 
                "uint256",
                "bytes"
            ],[
                params.orderId,
                params.validatorAddress,
                params.agentAddress,
                params.clientAddress,
                params.stakeDuration,
                params.stakeAmount,
                params.nonce,
                signature
            ]
        );
        const beforeClientStakeBalance = await  ethers.provider.getBalance(params.clientAddress);
        const beforeContractBalance = await  ethers.provider.getBalance(stakingAddress);
        console.log("beforeClientStakeBalance:",ethers.utils.formatEther(beforeClientStakeBalance));
        console.log("beforeContractBalance:",ethers.utils.formatEther(beforeContractBalance));

        const tx1 = await staking.connect(client).clientStake(data,{
            value: ethers.utils.parseEther("5"), 
            gasLimit: 1_000_000,
        });
        await tx1.wait();

        const afterClientStakeBalance = await  ethers.provider.getBalance(params.clientAddress);
        const afterContractBalance = await  ethers.provider.getBalance(stakingAddress);
        console.log("afterClientStakeBalance:",ethers.utils.formatEther(afterClientStakeBalance));
        console.log("afterContractBalance:",ethers.utils.formatEther(afterContractBalance));
    });

    it("clientnode",async () => {
        console.log("client info:",await validateNode.getClient(client.address));
    })

    it("test reward generate",async () => {
        const beforeOwnerBalance = await  ethers.provider.getBalance(owner.address);
        const beforeContractBalance = await  ethers.provider.getBalance(rewardAddress);
        console.log("beforeOwnerBalance:",ethers.utils.formatEther(beforeOwnerBalance));
        console.log("beforeContractBalance:",ethers.utils.formatEther(beforeContractBalance));

        const tx = await reward.connect(owner).generateRewards(20251118,{
            value: ethers.utils.parseEther("5"), 
            gasLimit: 1_000_000,
        });
        await tx.wait();

        const afterOwnerBalance = await  ethers.provider.getBalance(owner.address);
        const afterContractBalance = await  ethers.provider.getBalance(rewardAddress);
        console.log("afterOwnerBalance:",ethers.utils.formatEther(afterOwnerBalance));
        console.log("afterContractBalance:",ethers.utils.formatEther(afterContractBalance));
    });

    it("withdrawReward",async () => {
        var params = {
            orderId:withdrawNonce.add(1),
            amount:ethers.utils.parseEther("5"),
            beneficiaryAddress:node.address,
            nonce:withdrawNonce
        };
        const types = {
            Permit: [
                { name: "orderId", type: "uint256" },
                { name: "amount", type: "uint256" },
                { name: "beneficiaryAddress", type: "address" },
                { name: "nonce", type: "uint256" },
            ],
        };
        const domain = {
            name: "StakingRewardDistribute",
            version: "1",
            chainId: (await ethers.provider.getNetwork()).chainId,
            verifyingContract: rewardAddress,
        };

        const signature = await owner._signTypedData(domain, types, params);
        const data = ethers.utils.defaultAbiCoder.encode(
            [
                "uint256",
                "uint256",
                "address", 
                "uint256",
                "bytes"
            ],[
                params.orderId,
                params.amount,
                params.beneficiaryAddress,
                params.nonce,
                signature
            ]
        );


        const beforeNodeBalance = await  ethers.provider.getBalance(node.address);
        const beforeContractBalance = await  ethers.provider.getBalance(rewardAddress);
        console.log("beforeNodeBalance:",ethers.utils.formatEther(beforeNodeBalance));
        console.log("beforeContractBalance:",ethers.utils.formatEther(beforeContractBalance));

        const tx = await reward.connect(owner).withdrawReward(data,{
            gasLimit: 1_000_000,
        });
        await tx.wait();

        const afterNodeBalance = await  ethers.provider.getBalance(node.address);
        const afterContractBalance = await  ethers.provider.getBalance(rewardAddress);
        console.log("afterNodeBalance:",ethers.utils.formatEther(afterNodeBalance));
        console.log("afterContractBalance:",ethers.utils.formatEther(afterContractBalance));



    });

   



});

/**
 * 

npx hardhat test ./test/pijsStaking/NodeManage.test.ts --network ganache  --grep "withdrawReward"

*/