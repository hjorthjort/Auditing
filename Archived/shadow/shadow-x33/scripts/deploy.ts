import { deploy } from "../utils/deployment";
import { MainConfig } from "../utils/configs";
import fs from "fs";

async function main() {
  const contracts = await deploy(MainConfig);
  const table = await Promise.all(
    Object.entries(contracts).map(async ([key, value]) => {
      const address =
        typeof value === "string" ? value : await value.getAddress();

      return {
        Contract: key,
        Address: address,
      };
    }),
  );

  console.table(table);

  let markdownTable = "| Contract | Address |\n|----------|---------|\n";
  table.forEach((row) => {
    markdownTable += `| ${row.Contract} | ${row.Address} |\n`;
  });

  fs.writeFileSync("deployedAddresses.md", markdownTable, "utf8");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
