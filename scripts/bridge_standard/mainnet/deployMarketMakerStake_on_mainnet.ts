import { id } from "ethers/lib/utils";
import { ethers, upgrades } from "hardhat";
import {StakingUAG,MarketMakerStake} from  "../../../typechain-types";
async function main(){
    const [owner,user1] = await ethers.getSigners();
    const marketMakerStakeFactory = await ethers.getContractFactory('MarketMakerStake');
    const signer = '0xf504551185c4b3ee73e9d96eea06e3fd4210e601';
    const uagAddress = '0xe6Abc3Efd6818f20143D7587dCac5cb336F93640';
    const uacAddress = '0xE1bB8D9B24d8e5b6e7517A8e9eA23f77621a5FFF';
    const usdtAddress = '0x3F00C9dd4F081D7b6b758555c621FbEb09d519FD';
    
    const feeAddress = '0x084318D11E550fEc79040fE84032Ed9d12266338';
    
    const gensisNodeDistribute = '0xf504551185c4b3ee73e9d96eea06e3fd4210e601';
    const ecoDevAddress = '0xE383D646ef73229421Ebf607d4CCe2B199a12078'; // 生态建设
    const insuranceWarehouse = '0x4f5f15f22206347471b0C0555d78EBec9a96e8D6';  // 保险仓

    const args = [signer,uagAddress,uacAddress,usdtAddress,feeAddress,gensisNodeDistribute,ecoDevAddress,insuranceWarehouse];
    
    // const marketMakerStake =  (await upgrades.deployProxy(marketMakerStakeFactory,args,{kind:'uups'})) as MarketMakerStake;
    const marketMakerStake = await upgrades.upgradeProxy('0x133b395ec56B7c901AAF793Aa1E4c7Ef9981A74f', marketMakerStakeFactory, { kind: 'uups' });
    await marketMakerStake.deployed();

    // const marketMakerStake  = await ethers.getContractAt('0x00d93AC8517d835B98030330bEeA955c4144E643','MarketMakerStake');
    console.log("MarketMakerStake address is:",marketMakerStake.address);

    /// only for test
    // const tx1 = await marketMakerStake.setMarketMakerStakeTypeNumber(30,1000);
    // await tx1.wait();
    // const tx2 = await marketMakerStake.setMarketMakerStakeTypeNumber(60,1000);
    // await tx2.wait();
    // const tx3 = await marketMakerStake.setMarketMakerStakeTypeNumber(90,1000);
    // await tx3.wait();
    // const tx4 = await marketMakerStake.setMarketMakerStakeTypeNumber(180,1000);
    // await tx4.wait();

    // const tx11 = await marketMakerStake.setReleaseTypeMap(0,200);
    // await tx11.wait();
    // const tx22 = await marketMakerStake.setReleaseTypeMap(10,150);
    // await tx22.wait();
    // const tx33 = await marketMakerStake.setReleaseTypeMap(20,100);
    // await tx33.wait();
    // const tx44 = await marketMakerStake.setReleaseTypeMap(30,50);
    // await tx44.wait();


    // const tx111 = await marketMakerStake.setMarketMakerStakeTypeNumber(30*60,1000);
    // await tx111.wait();
    // const tx222 = await marketMakerStake.setMarketMakerStakeTypeNumber(60*60,1000);
    // await tx222.wait();
    // const tx333 = await marketMakerStake.setMarketMakerStakeTypeNumber(90*60,1000);
    // await tx333.wait();
    // const tx444 = await marketMakerStake.setMarketMakerStakeTypeNumber(180*60,1000);
    // await tx444.wait();

    // const tx1111 = await marketMakerStake.setReleaseTypeMap(0,200);
    // await tx1111.wait();
    // const tx2222 = await marketMakerStake.setReleaseTypeMap(10*60,150);
    // await tx2222.wait();
    // const tx3333 = await marketMakerStake.setReleaseTypeMap(20*60,100);
    // await tx3333.wait();
    // const tx4444 = await marketMakerStake.setReleaseTypeMap(30*60,50);
    //await tx4444.wait();
    
/**
     const ratio:[number, number, number, number] = [15,10,25,50];
    const tx = await marketMakerStake.setUacdistributeRadio(ratio);
    await tx.wait();
    console.log("ratio:",await marketMakerStake.getUacdistributeRadio());

    const feeReceiver = feeAddress;
    const withdrawPercent = 30;

    const tx1 = await marketMakerStake.setWithdrawPercent(withdrawPercent);
    await tx1.wait();
    console.log("withdrawPercent:",await marketMakerStake.getWithdrawPercent());

    const tx2 = await marketMakerStake.setFeeReceiver(feeReceiver);
    await tx2.wait();
    console.log("feeReceiver:",await marketMakerStake.getFeeReceiver());

    const tx3 = await marketMakerStake.setUacDistributeAddress(
        ['0x0000000000000000000000000000000000000000',gensisNodeDistribute,ecoDevAddress,insuranceWarehouse]
    );
    await tx3.wait();
    console.log("uacDistributeAddress:",await marketMakerStake.getUacDistributeAddress());

     */



}

main().catch(
    error => {
        console.log(error);
        process.exitCode = 1;
    }
);


/**
npx hardhat run ./scripts/bridge_standard/mainnet/deployMarketMakerStake_on_mainnet.ts --network pijs
MarketMakerStake address is: 0x133b395ec56B7c901AAF793Aa1E4c7Ef9981A74f
 */