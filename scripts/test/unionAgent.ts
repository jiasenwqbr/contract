import { id } from "ethers/lib/utils";
import { ethers, upgrades } from "hardhat";
import {LPLocker} from  "../../typechain-types";
import * as XLSX from "xlsx";
import * as fs from "fs";
async function main(){
    const [owner,user1,user2] = await ethers.getSigners();
    // let addr = "0x2DfB5e79F812011Ab8Fec30Ad7847189fB92618f";
    const pages = readExcelInPages("/Users/jason/Desktop/code/web3/bridge/scripts/test/result.xls",3000);
    const outputPath =
        "/Users/jason/Desktop/code/web3/bridge/scripts/test/result_with_balance.csv";
    const writeStream = fs.createWriteStream(outputPath, {
        flags: "w",
        encoding: "utf-8",
    });
    writeStream.write("id,addr,balance_eth\n");
    for (const [index, page] of pages.entries()) {
        console.log(`处理第 ${index + 1} 页，共 ${page.length} 行`);
        // console.log(page);
        
        // let idList = [];
        // let addrList= [];
        
        for (let i = 0; i < page.length; i++) {
            // idList.push(page[i].id);
            // addrList.push(page[i].addr);
            try {
                const balance = await ethers.provider.getBalance(page[i].addr);
                const balanceEth = ethers.utils.formatEther(balance);
                console.log(
                        page[i].id,
                        page[i].addr,
                        balanceEth
                    );

                writeStream.write(
                    `${page[i].id},${page[i].addr},${balanceEth}\n`
                );
                
            } catch (error) {
                console.error(
                    `第 ${index + 1} 页第 ${i + 1} 行失败`,
                    error
                );
                continue;
            }
        }
        writeStream.end();
    }

}

main().catch(
    error => {
        console.log(error);
        process.exitCode = 1;
    }
);



// 分页读取 Excel
function readExcelInPages(filePath: string, pageSize: number) {
  // 读取 Excel 文件
  const workbook = XLSX.readFile(filePath);

  // 获取第一个工作表
  const sheetName = workbook.SheetNames[0];
  const sheet = workbook.Sheets[sheetName];

  // 转成 JSON 数组（每一行是一个对象）
  const rows: any[] = XLSX.utils.sheet_to_json(sheet, { defval: "" });

  // 分页
  const pages: any[][] = [];
  for (let i = 0; i < rows.length; i += pageSize) {
    const page = rows.slice(i, i + pageSize);
    pages.push(page);
  }

  return pages;
}

/**
 * 
    npx hardhat run ./scripts/test/unionAgent.ts --network uac
 */

