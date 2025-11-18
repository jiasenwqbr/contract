import { id } from "ethers/lib/utils";
import { ethers, upgrades } from "hardhat";
import {RewardDistributeUAG} from  "../../../typechain-types";

async function main(){
    const [owner,user1] = await ethers.getSigners();
    const signer = '0xd4f0f0c79a35f217e5de4bff0752ba63cbc013e9';
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
    // const rewardDistributeUAG = await upgrades.upgradeProxy('0x4110E09f615dcE2BC6F75f1fC6713310CC554BcC', rewardDistributeUAGFactory, { kind: 'uups' });
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
npx hardhat run ./scripts/bridge_standard/testnet/deploy_RewardDistributeUAG_testnet.ts --network pijstestnet

rewardDistributeUAG address is: 0x4110E09f615dcE2BC6F75f1fC6713310CC554BcC
feeReceiver: 0x084318D11E550fEc79040fE84032Ed9d12266338
uacdistributeRadio: [
  BigNumber { value: "15" },
  BigNumber { value: "10" },
  BigNumber { value: "25" },
  BigNumber { value: "50" }
]
uacDistributeAddress: [
  '0x0000000000000000000000000000000000000000',
  '0xf504551185C4B3ee73e9D96eeA06e3FD4210E601',
  '0xE383D646ef73229421Ebf607d4CCe2B199a12078',
  '0x4f5f15f22206347471b0C0555d78EBec9a96e8D6'
]
 */