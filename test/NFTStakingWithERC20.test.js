const {expect} = require('chai');
const {ethers, upgrades} = require('hardhat');

describe('NFT Staking With ERC20 Contract', function() {
  let instanceToken;
  let instanceNFT;
  let instanceController;

  beforeEach(async () => {
    // deploy the token
    const MyToken = await ethers.getContractFactory("MyToken");
    instanceToken = await upgrades.deployProxy(MyToken); // use the upgradeable patterns
    await instanceToken.deployed();
    console.log("MyToken Contract address:", instanceToken.address);

    // then the NFT
    const MyNFTContract = await ethers.getContractFactory("MyNFT");
    instanceNFT = await upgrades.deployProxy(MyNFTContract);
    await instanceNFT.deployed();
    console.log("MyNFT Contract address:", instanceNFT.address);

    // now deploy the controller
    const Controller = await ethers.getContractFactory("Controller");
    instanceController = await upgrades.deployProxy(Controller, [instanceNFT.address, instanceToken.address]);
    await instanceController.deployed();
    console.log("Controller Contract address:", instanceController.address);
  });

  it('should deploy to an address', async () => {

    expect(await instanceToken.address).to.not.be.null;
    expect(await instanceToken.address).to.be.properAddress;

    expect(await instanceNFT.address).to.not.be.null;
    expect(await instanceNFT.address).to.be.properAddress;

    expect(await instanceController.address).to.not.be.null;
    expect(await instanceController.address).to.be.properAddress;
  });
});