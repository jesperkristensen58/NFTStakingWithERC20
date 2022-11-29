// Assuming an existing NFT contract has been deployed
// we now upgrade it to the NFT god mode
const {ethers, upgrades} = require('hardhat');

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log('Upgrading the proxy NFT contract.');

  console.log('============================================================');
  console.log('DEPLOYER:');
  console.log('Deploying contracts with the account: ', deployer.address);
  console.log('Account balance:                      ', (await deployer.getBalance()).toString());
  console.log('============================================================');

  // the existing NFT deployed on Goerli:
  const EXISTING_NFT_ADDRESS = "0x6B16dd3D4439feFA3e64cc98b907B5F3630C8b40";

  // now we upgrade to god mode
  const MyNFTGodMode = await ethers.getContractFactory("MyNFTGodMode");
  const upgraded = await upgrades.upgradeProxy(EXISTING_NFT_ADDRESS, MyNFTGodMode);

  console.log("Upgraded contract: ", upgraded.address);
}

main()
.then(() => process.exit(0))
.catch((error) => {
  console.error(error);
  process.exit(1);
});
