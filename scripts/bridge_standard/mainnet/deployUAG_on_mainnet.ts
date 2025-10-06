import { id } from "ethers/lib/utils";
import { ethers, upgrades } from "hardhat";

async function main(){
   
   const [owner] = await ethers.getSigners();
    const receiver = '0x727522774ADBD3340E8D420f8d0F45100A3863e1';

    const router02_address = '0xDd682E7BE09F596F0D0DEDD53Eb75abffDcd2312';
    const usdt_address = '0x08aD141eadFC93cD4e1566c31E1fb49886D5b80B';
    const wpijs = '0x30FF9d7E86Cbc55E970a6835248b30B21BD1390E';
   
    // const operator_address = '0xd4f0f0c79a35f217e5de4bff0752ba63cbc013e9';

    const uagFactory = await ethers.getContractFactory("UAGERC20");
    const uag = await uagFactory.deploy(receiver,usdt_address,router02_address,owner.address,wpijs);
    await uag.deployed();
    console.log("UAG address is:",uag.address);

    const tokenA = uag.address;
    const tokenB = "0x08aD141eadFC93cD4e1566c31E1fb49886D5b80B"; // USDT
    const factoryAddress = "0x144590c6C9ce4B352943a6BA17F1748aAe0E3BAd"; // PiJFactory
    const factory = await ethers.getContractAt("PiJFactory",factoryAddress);
    const pairAddress = await factory.getPair(tokenA, tokenB);
    console.log("UAG/USDT pairAddress is:",pairAddress);


     //    手续费
    const tx = await uag.setBuyFeeReceivers(
        ['0xb6b3bf25a787182f4a45535a5228730873cecd6d','0x311b3D4aA8ef16874C11f11880ADaa2146aBEAbd'],
        [10,10]
    );
    await tx.wait();

    const tx1 = await uag.setSellFeeReceivers(
         ['0xb6b3bf25a787182f4a45535a5228730873cecd6d','0x311b3D4aA8ef16874C11f11880ADaa2146aBEAbd'],
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
 
npx hardhat run ./scripts/bridge_standard/testnet/deployUAG_on_mainnet.ts --network pijstestnet

UAG address is: 0x670E979dEeDac422f008D6e8fe576DE121D86027
pairAddress is:  0x2F5699AbFcCa0FBD45D87b698c5D73295Bcce2a1
 */