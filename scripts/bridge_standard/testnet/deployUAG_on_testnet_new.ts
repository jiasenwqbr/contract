import { id } from "ethers/lib/utils";
import { ethers, upgrades } from "hardhat";

async function main(){

   const [owner] = await ethers.getSigners();
    const receiver = '0xb98E2E18259057076b3170c078F361978768d001';

   const router02_address = '0x32AEf11Bd9E1FBf8990CDB501b2632DA4fD76D01';
    const usdt_address = '0x3F00C9dd4F081D7b6b758555c621FbEb09d519FD';
    const wpijs = '0x0A8C16f9Ed042cf71BeB49e8d8854D189c704aDb';
   
    // const operator_address = '0xd4f0f0c79a35f217e5de4bff0752ba63cbc013e9';

    const uagFactory = await ethers.getContractFactory("UAGERC20");
    const uag = await uagFactory.deploy(receiver,usdt_address,router02_address,owner.address,wpijs);
    await uag.deployed();
    console.log("UAG address is:",uag.address);

    const tokenA = uag.address;
    const tokenB = "0x3F00C9dd4F081D7b6b758555c621FbEb09d519FD"; // USDT
    const factoryAddress = "0x113D5ef4c6FE6f2edBcF6915Bf7582c09F342499"; // PiJFactory
    const factory = await ethers.getContractAt("PiJFactory",factoryAddress);
    const pairAddress = await factory.getPair(tokenA, tokenB);
    console.log("UAG/USDT pairAddress is:",pairAddress);


     //    手续费
    const tx = await uag.setBuyFeeReceivers(
        ['0xd4f0f0c79a35f217e5de4bff0752ba63cbc013e9','0xd4f0f0c79a35f217e5de4bff0752ba63cbc013e9'],
        [10,10]
    );
    await tx.wait();

    const tx1 = await uag.setSellFeeReceivers(
         ['0xd4f0f0c79a35f217e5de4bff0752ba63cbc013e9','0xd4f0f0c79a35f217e5de4bff0752ba63cbc013e9'],
         [10,10]
    );
    await tx1.wait();

    const tx2 = await uag.batchUpdateGlobalWhitelist([owner.address,
        '0x466D44EFBf7F1035Feba1F0BdC6fEDE9Bd0729F4',
        '0xBDfb7B3cDDd4DE4F36fedFf836D25ED2365B146c'
    ],true,{
        gasLimit:12000000
    });
    await tx2.wait();




}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});

/***
 * 
npx hardhat run ./scripts/bridge_standard/testnet/deployUAG_on_testnet_new.ts --network pijstestnet
UAG address is: 0xACfB54616A301c205375d8001a4F8ddc4CD143D5
UAG/USDT pairAddress is: 0xA69725e38c03d26431e4A827BB1Acc7b77d04987

 */