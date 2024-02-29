import { ethers } from "hardhat";

async function main() {
  const KEYHASH =
    "0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c";
  const SUBSCRIPTION_ID = 0; //add your own subscription id
  const CALLBACK_GAS_LIMT = 50000;
  const VRFCOORDINATOR = "0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625";
  const TOKEN_NAME = "Grand Prize Token";
  const TOKEN_SYMBOL = "GPT";
  const TOTALSUPPLY = 1000000000000000;
  const DECIMAL = 6;

  const grandPrize = await ethers.deployContract("GrandPrize", [
    KEYHASH,
    SUBSCRIPTION_ID,
    CALLBACK_GAS_LIMT,
    VRFCOORDINATOR,
    TOKEN_NAME,
    TOKEN_SYMBOL,
    DECIMAL,
    TOTALSUPPLY,
  ]);

  await grandPrize.waitForDeployment();

  console.log(`deployed to ${grandPrize.target}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
