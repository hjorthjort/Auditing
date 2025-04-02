import { testDeploy } from "../utils/testDeployment";

async function main() {
    const contracts = await testDeploy();
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
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
