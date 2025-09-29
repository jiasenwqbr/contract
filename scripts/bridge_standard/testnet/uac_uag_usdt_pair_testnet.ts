import { id } from "ethers/lib/utils";
import { ethers, upgrades } from "hardhat";
import {SourceBridge} from  "../../../typechain-types";

async function main(){
     let [owner,operator,user1,user2,signer] = await ethers.getSigners();
     const factoryAddress = "0x113D5ef4c6FE6f2edBcF6915Bf7582c09F342499"; // PiJFactory
    // const tokenA = "0x74Da8060025a069Be3A6986Ef244D711034cfabA"; // UACERC20
    const tokenA = "0x670E979dEeDac422f008D6e8fe576DE121D86027"; // UAG
    const tokenB = "0x3F00C9dd4F081D7b6b758555c621FbEb09d519FD"; // USDT
    const factory = await ethers.getContractAt("PiJFactory",factoryAddress);
    const router02_address = '0x32AEf11Bd9E1FBf8990CDB501b2632DA4fD76D01';
    const uag_pairAddress = await factory.getPair(tokenA, tokenB);
    console.log("uag_pairAddress is: ",uag_pairAddress);


}


main().catch(
    error => {
        console.log(error);
        process.exitCode = 1;
    }
);

/**

npx hardhat run ./scripts/bridge_standard/testnet/deployUAC_on_testnet.ts --network pijstestnet


 */