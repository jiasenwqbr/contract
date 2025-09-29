import { id } from "ethers/lib/utils";
import { ethers, upgrades } from "hardhat";

async function main(){
    const [owner] = await ethers.getSigners();

    const uagFactory = await ethers.getContractFactory("UAGERC20");
    const receiver = '0xb98E2E18259057076b3170c078F361978768d001';
    const router02_address = '0x32AEf11Bd9E1FBf8990CDB501b2632DA4fD76D01';
    const usdt_address = '0x3F00C9dd4F081D7b6b758555c621FbEb09d519FD';
    const buyFeeReceiver = '0xb98E2E18259057076b3170c078F361978768d001';
    const sellFeeReceiver = '0xb98E2E18259057076b3170c078F361978768d001';
    const wpijs = '0x0A8C16f9Ed042cf71BeB49e8d8854D189c704aDb';
    const uag = await uagFactory.deploy(receiver,usdt_address,router02_address,owner.address,wpijs);
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
 
npx hardhat run ./scripts/bridge_standard/testnet/deployUAG_on_testnet.ts --network pijstestnet

UAG address is: 0x670E979dEeDac422f008D6e8fe576DE121D86027
pairAddress is:  0x2F5699AbFcCa0FBD45D87b698c5D73295Bcce2a1
 */