import { expect } from "chai";
import { ethers, upgrades } from "hardhat";
import { GenesisNode, NodeManage,IERC20} from "../../typechain-types";

describe("Node manage test",() => {
    let node:GenesisNode;
    let nodeManage:NodeManage;
    let gensisNode_address:any;
    let owner:any;
    let operator:any;
    let signer:any;
    const usdt_address = "0x3F00C9dd4F081D7b6b758555c621FbEb09d519FD";
    let usdtContract:any;


    beforeEach(async () => {
        [owner,operator] = await ethers.getSigners();
        signer = owner;
        gensisNode_address = '0x95158dD21b82d8D2f62aaB88f45E5e365e1B9f27';
        node = (
            await ethers.getContractAt("GenesisNode","0x6766876e5C822Ee01B44E6c2D9a5486492D9bA1A")
        ) as GenesisNode;

        // const nodeManageFactory = await ethers.getContractFactory("NodeManage");
        // const args = [signer.address,[operator.address,operator.address,operator.address],[300,300,300],usdt_address];
        // nodeManage = (await upgrades.deployProxy(nodeManageFactory,args,{initializer: "initialize",kind:'uups'})) as NodeManage;
        // await nodeManage.deployed();
        // console.log("NodeManage address is:",nodeManage.address);

        nodeManage = (
             await ethers.getContractAt("NodeManage","0x9e266493825E7139ADDceD2a61AD29bBdF43a7c7")
        ) as NodeManage;



        const tx2 = await node.grantRole(await node.OPERATOR_ROLE(),nodeManage.address);
        await tx2.wait();
        const hasRole = await node.hasRole(await node.OPERATOR_ROLE(),nodeManage.address);
        console.log("hasRole:",hasRole);

        const tx = await nodeManage.connect(owner).addProduct(1,gensisNode_address,true);
        await tx.wait();


        usdtContract = await  ethers.getContractAt("PIJS_USDT",usdt_address);
    });

    describe("buyNode test",() => {
        beforeEach(async ()=>{
            const params = {
                buyer:owner.address,
                orderId:2,
                tokenAddress:usdt_address,
                tokenAmount:ethers.utils.parseEther("1"),
                nodeAddress:gensisNode_address,
                buyAmount:1,
                recommender:operator.address,
                collectRatio:100
            };
            const types = {
                Permit: [
                    { name: "buyer", type: "address" },
                    { name: "orderId", type: "uint256" },
                    { name: "tokenAddress", type: "address" },
                    { name: "tokenAmount", type: "uint256" },
                    { name: "nodeAddress", type: "address" },
                    { name: "buyAmount", type: "uint256" },
                    { name: "recommender", type: "address" },
                    { name: "collectRatio", type: "uint256" },
                ],
            }
            const domain = {
                name: "NodeManage",
                version: "1",
                chainId: (await ethers.provider.getNetwork()).chainId,
                verifyingContract: nodeManage.address,
            };
            const signature = await signer._signTypedData(domain,types,params);
            const data =  ethers.utils.defaultAbiCoder.encode(
                    [
                        "address",
                        "uint256",
                        "address",
                        "uint256", 
                        "address",
                        "uint256",
                        "address", 
                        "uint256",
                        "bytes"
                    ],[
                        params.buyer,
                        params.orderId,
                        params.tokenAddress,
                        params.tokenAmount,
                        params.nodeAddress,
                        params.buyAmount,
                        params.recommender,
                        params.collectRatio,
                        signature
                    ]
                );

            const tx1 = await usdtContract.connect(owner).approve(nodeManage.address,ethers.utils.parseEther("5"));
            await tx1.wait();
            const tx = await nodeManage.connect(owner).buyNode(data,{gasLimit: 1_000_000,});
            await tx.wait();

            console.log(tx);



        });

        it("The balance is right",async ()=> {

        });
    });
});

/**
 * 
npx hardhat test ./test/node/NodeManage.test.ts --network pijstestnet

 */