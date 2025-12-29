import { id } from "ethers/lib/utils";
import { ethers, upgrades } from "hardhat";
import { UACBSC ,StakeUACOnBscUpgradeble} from  "../../../typechain-types";
import fs from "fs";
import csv from "csv-parser";
import { BigNumber } from "ethers";

interface Row {
    id: string;
    addr: string;
    pow_earn:Number;
    referee_pos_earn:Number;
    pos_earn:Number;
    additional:number;
    earn_num:number;
    balance_eth:Number;
    stake_num:Number;
    total:Number;
}   

async function main(){
    const [owner,user1,user2,user3] = await ethers.getSigners();
    const uac_address = "0x62f59D17B395B4437Cc4C673d075b898D2d95eAe";
    const stake_address = "0xA8b329BfAbEC58346F7a3aC5Fb23689919131b8F";

    const uac = await ethers.getContractAt("UACBSC",uac_address) as UACBSC;

    //console.log(ethers.utils.formatEther(await uac.balanceOf("0x0741d7bb4aaf854f046b9e9e1a499ca4c74a4316")));
     console.log(ethers.utils.formatEther(await uac.balanceOf(owner.address)));
    
    await checkBalance(uac);

    

      
}


main().catch(
    error => {
        console.log(error);
        process.exitCode = 1;
    }
);


async function checkBalance(uac:UACBSC){
    // 检查线上用户的余额
    const rows = await readCSV("/Users/jason/Desktop/code/web3/bridge/scripts/uacbsc_stake/mainnet/intergrate.csv");
        
    
        console.log("------------------------------------------------------------------------",rows.length);
        let totalSum = ethers.constants.Zero;
        let totalSumBalance = ethers.constants.Zero;
        for (let i = 0; i< rows.length;i++){
            // console.log(
            //             i,rows[i].id,rows[i].addr, rows[i].total
            // );

            totalSum = totalSum.add(
                ethers.utils.parseEther(rows[i].total.toString())
            );

            const balance = await uac.balanceOf(rows[i].addr);
            totalSumBalance = totalSumBalance.add(
                balance
            );
            
            if (ethers.utils.parseEther(rows[i].total.toString()).eq(balance)){
                // console.log(rows[i].id,rows[i].addr,"is correct");
            } else {
                console.log(i,rows[i].id,rows[i].addr,ethers.utils.parseEther(rows[i].total.toString()),balance,"is correct?");
                console.log(i,rows[i].id,rows[i].addr,"is not correct");
            }

        }

        console.log("------------------------------------------------------------------------totalSum:", ethers.utils.formatEther(totalSum));
        console.log("------------------------------------------------------------------------totalSumBalance:", ethers.utils.formatEther(totalSumBalance));
}


function sleep(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms));
}

function readCSV(path: string): Promise<Row[]> {
    return new Promise((resolve, reject) => {
        const results: Row[] = [];
        fs.createReadStream(path)
            .pipe(csv())
            .on("data", (data: Row) => {
                results.push(data);
            })
            .on("end", () => {
                resolve(results);
            })
            .on("error", reject);
    });
}




/**
 * 
  npx hardhat run ./scripts/uacbsc_stake/mainnet/05testDeployed-mainnet.ts --network bscmainnet
  
 */
