import { id } from "ethers/lib/utils";
import { ethers, upgrades } from "hardhat";

async function main(){

   const [owner] = await ethers.getSigners();
    const receiver = '0x727522774ADBD3340E8D420f8d0F45100A3863e1';

    const router02_address = '0xDd682E7BE09F596F0D0DEDD53Eb75abffDcd2312';
    const usdt_address = '0x08aD141eadFC93cD4e1566c31E1fb49886D5b80B';
    const wpijs = '0x30FF9d7E86Cbc55E970a6835248b30B21BD1390E';
   
    // const operator_address = '0xd4f0f0c79a35f217e5de4bff0752ba63cbc013e9';

    const uacFactory = await ethers.getContractFactory("UACToken");
    const uac = await uacFactory.deploy(receiver,usdt_address,router02_address,owner.address,wpijs);
    await uac.deployed();
    console.log("UAC address is:",uac.address);

    const tokenA = uac.address;
    const tokenB = "0x08aD141eadFC93cD4e1566c31E1fb49886D5b80B"; // USDT
    const factoryAddress = "0x144590c6C9ce4B352943a6BA17F1748aAe0E3BAd"; // PiJFactory
    const factory = await ethers.getContractAt("PiJFactory",factoryAddress);
    const pairAddress = await factory.getPair(tokenA, tokenB);
    console.log("UAC/USDT pairAddress is:",pairAddress);


     //    手续费
    const tx = await uac.setBuyFeeReceivers(
        ['0xafD34ac5978e635D6352575E253Ba3b35c11cc18','0xf504551185c4b3ee73e9d96eea06e3fd4210e601'],
        [10,10]
    );
    await tx.wait();

    const tx1 = await uac.setSellFeeReceivers(
         ['0xafD34ac5978e635D6352575E253Ba3b35c11cc18','0xf504551185c4b3ee73e9d96eea06e3fd4210e601'],
         [10,10]
    );
    await tx1.wait();

    const tx2 = await uac.batchUpdateGlobalWhitelist([owner.address,
        '0x466D44EFBf7F1035Feba1F0BdC6fEDE9Bd0729F4',
        '0xBDfb7B3cDDd4DE4F36fedFf836D25ED2365B146c'
    ],true,{
        gasLimit:12000000
    });
    await tx2.wait();



    // const uac = await ethers.getContractAt("FreezenUAC","0x07a4DCf08F3345E5f3aeE7E5edc81Ece9Ae8b234");
    // const tx1 = await uac.setTradeToPublic(true);
    // await tx1.wait();

    // const tx11 = await uac.connect(owner).setBuyFeeReceiver('0xd4f0f0c79a35f217e5de4bff0752ba63cbc013e9');
    // await tx11.wait();

    // const tx111 = await uac.connect(owner).setSellFeeReceiver('0xd4f0f0c79a35f217e5de4bff0752ba63cbc013e9');
    // await tx111.wait();


    // const uag = await ethers.getContractAt("FreezenUAC","0x670E979dEeDac422f008D6e8fe576DE121D86027");
    // const tx2 = await uag.setTradeToPublic(true);
    // await tx2.wait();

    //  const tx22 = await uag.connect(owner).setBuyFeeReceiver('0xd4f0f0c79a35f217e5de4bff0752ba63cbc013e9');
    // await tx22.wait();

    // const tx222 = await uag.connect(owner).setSellFeeReceiver('0xd4f0f0c79a35f217e5de4bff0752ba63cbc013e9');
    // await tx222.wait();



}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});

/***
 * 
npx hardhat run ./scripts/bridge_standard/mainnet/deployUAC_on_mainnet.ts --network pijs
UAC address is: 0xE1bB8D9B24d8e5b6e7517A8e9eA23f77621a5FFF
UAC/USDT pairAddress is: 0x14AA54Ba49D6f503410B950027f073ad71460890

 */