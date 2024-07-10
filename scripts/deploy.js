const hre = require("hardhat");

async function main() {
  const Galang = await hre.ethers.getContractFactory("Galang");
  const galang = await Galang.deploy();

  await galang.deploymentTransaction().wait();

  const address = await galang.getAddress();

  console.log("Galang deployed to:", address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
