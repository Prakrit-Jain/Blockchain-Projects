const { ethers } = require('hardhat');

// array of contract addresses to pass in contructor
const contractAddresses = [];

// array of contract descriptions to pass in constructor
const descriptions = [];

// max loops limit to pass in constructor
const maxLoopsLimit = 100;

async function main() {

  const contractManagerFactory = await ethers.getContractFactory("ContractManager");

  console.log("contract manager is deploying........");
  const contractManager = await contractManagerFactory.deploy(contractAddresses, descriptions, maxLoopsLimit);

  console.log("contractManager deployed at address: ", await contractManager.getAddress());
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
