import { id } from "ethers/lib/utils";
import { ethers, upgrades } from "hardhat";
import {StakingUAG} from  "../../../typechain-types";
async function main(){
    const [owner] = await ethers.getSigners();
    const stakingUAGFactory = await ethers.getContractFactory('StakingUAG');
    const signer = '0xf504551185c4b3ee73e9d96eea06e3fd4210e601';
    const uagAddress = '0xe6Abc3Efd6818f20143D7587dCac5cb336F93640';
    const uacAddress = '0xE1bB8D9B24d8e5b6e7517A8e9eA23f77621a5FFF';
    const feeAddress = '0x084318D11E550fEc79040fE84032Ed9d12266338';
    const stakeAmountMin = ethers.utils.parseEther("5");
    const stakeAmountMax= ethers.utils.parseEther("1000");
    const withdrawalFeePersentage = 30;

    const gensisNodeDistribute = '0xf504551185c4b3ee73e9d96eea06e3fd4210e601';
    const ecoDevAddress = '0xE383D646ef73229421Ebf607d4CCe2B199a12078'; // 生态建设
    const insuranceWarehouse = '0x4f5f15f22206347471b0C0555d78EBec9a96e8D6';  // 保险仓

    const args = [
        signer,
        uagAddress,
        uacAddress,
        feeAddress,
        stakeAmountMin,
        stakeAmountMax,
        withdrawalFeePersentage,
        gensisNodeDistribute,
        ecoDevAddress,
        insuranceWarehouse
    ];

    // const stakingUAG =  (await upgrades.deployProxy(stakingUAGFactory,args,{kind:'uups'})) as StakingUAG;
    const stakingUAG = await upgrades.upgradeProxy('0x1D992B047459D36179d401eE467eaba54AafDf14', stakingUAGFactory, { kind: 'uups' });
    await stakingUAG.deployed();
    console.log("StakingUAG address is:",stakingUAG.address);
    const ratio:[number, number, number, number] = [15,10,25,50];
    const tx = await stakingUAG.setUacdistributeRadio(ratio);
    await tx.wait();
    console.log("ratio:",await stakingUAG.getUacdistributeRadio());

    const tx3 = await stakingUAG.setUacDistributeAddress(
        ['0x0000000000000000000000000000000000000000',gensisNodeDistribute,ecoDevAddress,insuranceWarehouse]
    );
    await tx3.wait();
    console.log("uacDistributeAddress:",await stakingUAG.getUacDistributeAddress());



    // modify
    // const stakingUAG = await ethers.getContractAt('StakingUAG','0x1D992B047459D36179d401eE467eaba54AafDf14');
    const tx4 = await stakingUAG.setStakeAmountLimit(stakeAmountMin,stakeAmountMax) ;
    await tx4.wait();

    console.log(await stakingUAG.getStakeAmountLimit());



}

main().catch(
    error => {
        console.log(error);
        process.exitCode = 1;
    }
);


/**
npx hardhat run ./scripts/bridge_standard/mainnet/deployStakingUAG_on_mainnet.ts --network pijs
StakingUAG address is: 0x1D992B047459D36179d401eE467eaba54AafDf14
 */