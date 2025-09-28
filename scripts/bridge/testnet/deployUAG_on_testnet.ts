import { id } from "ethers/lib/utils";
import { ethers, upgrades } from "hardhat";

async function main(){
    const [owner] = await ethers.getSigners();
    const receiver = '0xBB5EAccCEB5CBCfBD73d8Fb6bBd122eACa47ae37';
    const router02_address = '0x32AEf11Bd9E1FBf8990CDB501b2632DA4fD76D01';
    const uagFactory = await ethers.getContractFactory("UAGERC20");
    const usdt_address = '0x3F00C9dd4F081D7b6b758555c621FbEb09d519FD';
    const buyFeeReceiver = '0xBB5EAccCEB5CBCfBD73d8Fb6bBd122eACa47ae37';
    const sellFeeReceiver = '0xBB5EAccCEB5CBCfBD73d8Fb6bBd122eACa47ae37';
    const operator_address = '0xd4f0f0c79a35f217e5de4bff0752ba63cbc013e9';
    const uag = await uagFactory.deploy(receiver,usdt_address,router02_address,buyFeeReceiver,sellFeeReceiver,operator_address);
    await uag.deployed();
    console.log("UAG address is:",uag.address);

    const tokenA = uag.address;
    const tokenB = "0x3F00C9dd4F081D7b6b758555c621FbEb09d519FD"; // USDT
    const factoryAddress = "0x113D5ef4c6FE6f2edBcF6915Bf7582c09F342499"; // PiJFactory
    const factory = await ethers.getContractAt("PiJFactory",factoryAddress);
    const pairAddress = await factory.getPair(tokenA, tokenB);
    console.log("pairAddress is: ",pairAddress);
}


main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});

/***
 
npx hardhat run ./scripts/bridge/testnet/deployUAG_on_testnet.ts --network pijstestnet

 uag address is: 0x297F8e26B67A9E3E047eb0101666508F683b0cD7
pairAddress is:  0x0E205128eDF6F2A132881ce6411b4c13A828fC43
 */