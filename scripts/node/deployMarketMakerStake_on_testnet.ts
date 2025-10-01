import { id } from "ethers/lib/utils";
import { ethers, upgrades } from "hardhat";
import {StakingUAG,MarketMakerStake} from  "../../typechain-types";
async function main(){
    const [owner,user1] = await ethers.getSigners();
    const marketMakerStakeFactory = await ethers.getContractFactory('MarketMakerStake');
    const signer = '0xd4f0f0c79a35f217e5de4bff0752ba63cbc013e9';
    const uagAddress = '0x0b5E6Ef97FF0E013eB502735769e98fD4c538FE9';
    const uacAddress = '0xe15B602eF891D45251FF749BE97db6a983CdE175';
    const usdtAddress = '0x3F00C9dd4F081D7b6b758555c621FbEb09d519FD';
    const feeAddress = '0xBB5EAccCEB5CBCfBD73d8Fb6bBd122eACa47ae37';
    const gensisNodeDistribute = user1.address;
    const ecoDevAddress = user1.address;
    const insuranceWarehouse = user1.address;
    const args = [signer,uagAddress,uacAddress,usdtAddress,feeAddress,gensisNodeDistribute,ecoDevAddress,insuranceWarehouse];
    
    // const marketMakerStake =  (await upgrades.deployProxy(marketMakerStakeFactory,args,{kind:'uups'})) as MarketMakerStake;
    const marketMakerStake = await upgrades.upgradeProxy('0x00d93AC8517d835B98030330bEeA955c4144E643', marketMakerStakeFactory, { kind: 'uups' });
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

    const ratio = [15,10,25,50];
    const tx = await marketMakerStake.setUacdistributeRadio(ratio);
    await tx.wait();
    console.log("ratio:",await marketMakerStake.getUacdistributeRadio());

    const feeReceiver = '';
    const withdrawPercent = 30;

    const tx1 = await marketMakerStake.setWithdrawPercent(withdrawPercent);
    await tx1.wait();
    console.log("withdrawPercent:",await marketMakerStake.getWithdrawPercent());

    const tx2 = await marketMakerStake.setFeeReceiver(feeReceiver);
    await tx2.wait();
    console.log("feeReceiver:",await marketMakerStake.getFeeReceiver());



}

main().catch(
    error => {
        console.log(error);
        process.exitCode = 1;
    }
);


/**
npx hardhat run ./scripts/node/deployMarketMakerStake_on_testnet.ts --network pijstestnet
MarketMakerStake address is: 0x00d93AC8517d835B98030330bEeA955c4144E643
 */