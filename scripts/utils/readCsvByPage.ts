import fs from "fs";
import csv from "csv-parser";

export async function readCsvByPage<T>(
    filePath: string,
    pageSize: number,
    onPage: (page: T[], pageIndex: number) => Promise<void>
) {
    return new Promise<void>((resolve, reject) => {
        let page: T[] = [];
        let pageIndex = 0;

        fs.createReadStream(filePath)
            .pipe(csv())
            .on("data", async (row: T) => {
                page.push(row);

                if (page.length >= pageSize) {
                    fs.createReadStream(filePath).pause?.();
                    await onPage(page, pageIndex++);
                    page = [];
                }
            })
            .on("end", async () => {
                if (page.length > 0) {
                    await onPage(page, pageIndex++);
                }
                resolve();
            })
            .on("error", reject);
    });
}
