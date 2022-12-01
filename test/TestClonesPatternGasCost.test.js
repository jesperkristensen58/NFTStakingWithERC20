/**
 * @notice Test and compare gas costs between naive creation vs using the cloning pattern.
 * @author Jesper Kristensen (@cryptojesperk)
 */
const {expect} = require('chai');
const {ethers, upgrades} = require('hardhat');
const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");

describe('Clones Pattern Gas Cost', function() {
  let deployer;
  let alice;
  let bob;

  async function deployFixture() {
    [deployer, alice, bob] = await ethers.getSigners();

    // deploy the Token Factory
    const MyTokenFactory = await ethers.getContractFactory("MyTokenFactory");
    instanceTokenFactory = await MyTokenFactory.deploy();

    return { instanceTokenFactory, deployer, alice, bob };
  }

  it('Should deploy to a valid address', async () => {
    const {instanceTokenFactory} = await loadFixture(deployFixture);

    expect(await instanceTokenFactory.address).to.not.be.null;
    expect(await instanceTokenFactory.address).to.be.properAddress;
  });

  it('Should compare creation gas costs', async () => {
    /**
     * @dev The gas report will be produced via `npx hardhat test` automatically (see the hardhat config file where the snapshot report is enabled)
     * So below we just ensure to call the functions - we don't need to measure the gas here.
     */
    const {instanceTokenFactory} = await loadFixture(deployFixture);

    // let's create a new ERC20 based on the vanilla pattern
    let tx = await instanceTokenFactory.createNewERC20(10);
    await tx.wait();
    tx = await instanceTokenFactory.createNewERC20(20000);
    await tx.wait();
    
    // now try with the clones pattern
    tx = await instanceTokenFactory.createNewERC20WithClone(10);
    await tx.wait();
    tx = await instanceTokenFactory.createNewERC20WithClone(20000);
    await tx.wait();
  });
});