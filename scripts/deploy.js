const {ethers, upgrades} = require('hardhat');

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log('Deploying with a an upgradeable proxy pattern.');

  console.log('============================================================');
  console.log('DEPLOYER:');
  console.log('Deploying contracts with the account: ', deployer.address);
  console.log('Account balance:                      ', (await deployer.getBalance()).toString());
  console.log('============================================================');

  // deploy the token
  const MyToken = await ethers.getContractFactory("MyToken");
  const instanceToken = await upgrades.deployProxy(MyToken); // use the upgradeable patterns
  await instanceToken.deployed();
  console.log("MyToken Contract address:", instanceToken.address);

  // then the NFT
  const MyNFTContract = await ethers.getContractFactory("MyNFT");
  const instanceNFT = await upgrades.deployProxy(MyNFTContract);
  await instanceNFT.deployed();
  console.log("MyNFT Contract address:", instanceNFT.address);

  // now deploy the controller
  const Controller = await ethers.getContractFactory("Controller");
  const instanceController = await upgrades.deployProxy(Controller, [instanceNFT.address, instanceToken.address]);
  await instanceController.deployed();
  console.log("Controller Contract address:", instanceController.address);
}

main()
.then(() => process.exit(0))
.catch((error) => {
  console.error(error);
  process.exit(1);
});
