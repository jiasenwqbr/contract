import { id } from "ethers/lib/utils";
import { ethers, upgrades } from "hardhat";
import { queryRole } from "./roleUtils";

async function main() {
    const [owner, account1, account2, account3, account4] = await ethers.getSigners();
    let contrtact_address = '0x74Da8060025a069Be3A6986Ef244D711034cfabA';
    const erc20 = await ethers.getContractAt("UACERC20", contrtact_address);
    const manage_address = "0x656f1c8Add8b938285286F17ad2Db865234C9Cde";
  
    const operate_role_addresses = await queryRole(await erc20.OPERATE_ROLE(),erc20);
    console.log(`OPERATE_ROLE  : ${operate_role_addresses}`);
    

}



main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});


/**
 * 
npx hardhat run ./scripts/Bridge.address.validate.ts --network uac 
 
*/