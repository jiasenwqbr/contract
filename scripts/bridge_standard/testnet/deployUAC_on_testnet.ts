import { id } from "ethers/lib/utils";
import { ethers, upgrades } from "hardhat";

async function main(){

   const [owner] = await ethers.getSigners();
    const receiver = '0xb98E2E18259057076b3170c078F361978768d001';
    const router02_address = '0x32AEf11Bd9E1FBf8990CDB501b2632DA4fD76D01';
    const usdt_address = '0x3F00C9dd4F081D7b6b758555c621FbEb09d519FD';
    const buyFeeReceiver = '0xb98E2E18259057076b3170c078F361978768d001';
    const sellFeeReceiver = '0xb98E2E18259057076b3170c078F361978768d001';
    const wpijs = '0x0A8C16f9Ed042cf71BeB49e8d8854D189c704aDb';
   
    // const operator_address = '0xd4f0f0c79a35f217e5de4bff0752ba63cbc013e9';
    const operator_address = owner.address;
    const signer = '0xd4f0f0c79a35f217e5de4bff0752ba63cbc013e9';

    // const uacFactory = await ethers.getContractFactory("UACToken");
    // const uac = await uacFactory.deploy(receiver,usdt_address,router02_address,owner.address,wpijs);
    // await uac.deployed();
    // console.log("UAC address is:",uac.address);

    // const tokenA = uac.address;
    // const tokenB = "0x3F00C9dd4F081D7b6b758555c621FbEb09d519FD"; // USDT
    // const factoryAddress = "0x113D5ef4c6FE6f2edBcF6915Bf7582c09F342499"; // PiJFactory
    // const factory = await ethers.getContractAt("PiJFactory",factoryAddress);
    // const pairAddress = await factory.getPair(tokenA, tokenB);
    // console.log("pairAddress is:",pairAddress);

    const uac = await ethers.getContractAt("FreezenUAC","0x07a4DCf08F3345E5f3aeE7E5edc81Ece9Ae8b234");
    const tx1 = await uac.setTradeToPublic(true);
    await tx1.wait();

    const tx11 = await uac.connect(owner).setBuyFeeReceiver('0xd4f0f0c79a35f217e5de4bff0752ba63cbc013e9');
    await tx11.wait();

    const tx111 = await uac.connect(owner).setSellFeeReceiver('0xd4f0f0c79a35f217e5de4bff0752ba63cbc013e9');
    await tx111.wait();


    const uag = await ethers.getContractAt("FreezenUAC","0x670E979dEeDac422f008D6e8fe576DE121D86027");
    const tx2 = await uag.setTradeToPublic(true);
    await tx2.wait();

     const tx22 = await uag.connect(owner).setBuyFeeReceiver('0xd4f0f0c79a35f217e5de4bff0752ba63cbc013e9');
    await tx22.wait();

    const tx222 = await uag.connect(owner).setSellFeeReceiver('0xd4f0f0c79a35f217e5de4bff0752ba63cbc013e9');
    await tx222.wait();



}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});

/***
 * 
npx hardhat run ./scripts/bridge_standard/testnet/deployUAC_on_testnet.ts --network pijstestnet

UAC address is: 0x07a4DCf08F3345E5f3aeE7E5edc81Ece9Ae8b234
pairAddress is: 0x949CE898088B4b6e564E614c7F92f16B61B0ac67

 */