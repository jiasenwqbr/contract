import { id } from "ethers/lib/utils";
import { ethers, upgrades } from "hardhat";

async function main(){

   const [owner] = await ethers.getSigners();
    const receiver = '0xBB5EAccCEB5CBCfBD73d8Fb6bBd122eACa47ae37';
    const router02_address = '0x32AEf11Bd9E1FBf8990CDB501b2632DA4fD76D01';
    const usdt_address = '0x3F00C9dd4F081D7b6b758555c621FbEb09d519FD';
    const buyFeeReceiver = '0xBB5EAccCEB5CBCfBD73d8Fb6bBd122eACa47ae37';
    const sellFeeReceiver = '0xBB5EAccCEB5CBCfBD73d8Fb6bBd122eACa47ae37';
    // const operator_address = '0xd4f0f0c79a35f217e5de4bff0752ba63cbc013e9';
    const operator_address = owner.address;
    const signer = '0xd4f0f0c79a35f217e5de4bff0752ba63cbc013e9';

    const uacFactory = await ethers.getContractFactory("UACToken");
    const uac = await uacFactory.deploy(receiver,usdt_address,router02_address,buyFeeReceiver,sellFeeReceiver,operator_address,signer);
    await uac.deployed();
    console.log("UAC address is:",uac.address);

    const tokenA = uac.address;
    const tokenB = "0x3F00C9dd4F081D7b6b758555c621FbEb09d519FD"; // USDT
    const factoryAddress = "0x113D5ef4c6FE6f2edBcF6915Bf7582c09F342499"; // PiJFactory
    const factory = await ethers.getContractAt("PiJFactory",factoryAddress);
    const pairAddress = await factory.getPair(tokenA, tokenB);
    console.log("pairAddress is:",pairAddress);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});

/***
 * 
npx hardhat run ./scripts/bridge/testnet/deployUAC_on_testnet.ts --network pijstestnet

uac address is: 0x1658E47df21BBa645F1768d6883C259F3fA98B59
pairAddress is: 0x257938f53CbFb1afb62b7410f8cc7ff1D162B6F8

 */