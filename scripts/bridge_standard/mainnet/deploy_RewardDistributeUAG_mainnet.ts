import { id } from "ethers/lib/utils";
import { ethers, upgrades } from "hardhat";
import {RewardDistributeUAG} from  "../../../typechain-types";

async function main(){
    const [owner,user1] = await ethers.getSigners();
    const signer = '0xf504551185c4b3ee73e9d96eea06e3fd4210e601';
    const feeAddress = '0x084318D11E550fEc79040fE84032Ed9d12266338';
    const uacdistributeRadio:[number, number, number, number] = [15,10,25,50];
    const gensisNodeDistribute = '0xf504551185c4b3ee73e9d96eea06e3fd4210e601';
    const ecoDevAddress = '0xE383D646ef73229421Ebf607d4CCe2B199a12078'; // 生态建设
    const insuranceWarehouse = '0x4f5f15f22206347471b0C0555d78EBec9a96e8D6';  // 保险仓
    const  uacDistributeAddress= ['0x0000000000000000000000000000000000000000',gensisNodeDistribute,ecoDevAddress,insuranceWarehouse]
    const args = [
        signer,
        feeAddress,
        uacDistributeAddress,
        uacdistributeRadio
    ];

    const rewardDistributeUAGFactory = await ethers.getContractFactory('RewardDistributeUAG');
    const rewardDistributeUAG =  (await upgrades.deployProxy(rewardDistributeUAGFactory,args,{kind:'uups'})) as RewardDistributeUAG;
    // const rewardDistributeUAG = await upgrades.upgradeProxy('0x1D992B047459D36179d401eE467eaba54AafDf14', rewardDistributeUAGFactory, { kind: 'uups' });
    await rewardDistributeUAG.deployed();
    console.log("rewardDistributeUAG address is:",rewardDistributeUAG.address);
    // console.log("signer:",await rewardDistributeUAG.signer());
    console.log("feeReceiver:",await rewardDistributeUAG.feeReceiver());
    console.log("uacdistributeRadio:",await rewardDistributeUAG.getUacdistributeRadio());
    console.log("uacDistributeAddress:",await rewardDistributeUAG.getUacDistributeAddress());

}



main().catch(
    error => {
        console.log(error);
        process.exitCode = 1;
    }
);


/**
npx hardhat run ./scripts/bridge_standard/mainnet/deploy_RewardDistributeUAG_mainnet.ts --network pijs
MarketMakerStake address is: 0x133b395ec56B7c901AAF793Aa1E4c7Ef9981A74f
 */