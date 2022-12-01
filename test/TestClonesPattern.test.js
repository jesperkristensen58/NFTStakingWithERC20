/**
 * @notice Test the ERC20 Clones Pattern.
 * @author Jesper Kristensen (@cryptojesperk)
 */
const {expect} = require('chai');
const {ethers, upgrades} = require('hardhat');
const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");

describe('Clones Pattern', function() {
  let deployer;
  let alice;
  let bob;
  let instanceToken;
  
  async function deployFixture() {
    [deployer, alice, bob] = await ethers.getSigners();

    // deploy the token
    let MyToken = await ethers.getContractFactory("MyToken");
    instanceToken = await upgrades.deployProxy(MyToken, [1_000_000, "MyToken", "MYT", ethers.constants.AddressZero]); // use the upgradeable patterns
    await instanceToken.deployed();
    console.log("MyToken Contract address:", instanceToken.address);

    return { instanceToken, deployer, alice, bob };
  }

  it('Should deploy to a valid address', async () => {
    const {instanceToken} = await loadFixture(deployFixture);

    expect(await instanceToken.address).to.not.be.null;
    expect(await instanceToken.address).to.be.properAddress;
  });

  it('Should create clones with expected parameters', async () => {
    const {instanceToken} = await loadFixture(deployFixture);

    // confirm the cloner token details
    expect(await instanceToken.cap()).to.equal(ethers.BigNumber.from("1000000000000000000000000"));
    expect(await instanceToken.name()).to.equal("MyToken");
    expect(await instanceToken.symbol()).to.equal("MYT");

    // let's create a new ERC20 based on the vanilla pattern
    const tx = await instanceToken.clone(2, "MyNewToken", "MYNT", ethers.constants.AddressZero);
    await tx.wait();

    // fetch the cloned address from the event emitted
    const receipt = await ethers.provider.getTransactionReceipt(tx.hash);
    var abi = ["event Cloned(address indexed clonedAddress)"];
    let iface = new ethers.utils.Interface(abi);
    let log = iface.parseLog(receipt.logs[0]);
    let clonedAddress = log.args.clonedAddress;

    expect(clonedAddress).to.not.be.null;
    expect(clonedAddress).to.be.properAddress;
  });
});