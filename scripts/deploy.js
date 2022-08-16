async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);
  console.log("Account balance:", (await deployer.getBalance()).toString());

  // deploy the token
  const MyToken = await ethers.getContractFactory("MyToken");
  const myToken = await MyToken.deploy(10);
  console.log("MyToken Contract address:", myToken.address);

  // then the NFT
  const MyNFT = await ethers.getContractFactory("MyNFT");
  const myNFT = await MyNFT.deploy();
  console.log("MyNFT Contract address:", myNFT.address);

  // now deploy the controller
  const Controller = await ethers.getContractFactory("Controller");
  const controller = await Controller.deploy(myNFT.address, myToken.address);
  console.log("Controller Contract address:", controller.address);
}

main()
.then(() => process.exit(0))
.catch((error) => {
  console.error(error);
  process.exit(1);
});
