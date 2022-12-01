/**
 * @notice Test NFT Staking for Rewards.
 * @author Jesper Kristensen (@cryptojesperk)
 */
const {expect} = require('chai');
const {ethers, upgrades} = require('hardhat');
const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");

describe('NFT Staking With ERC20 Contract', function() {
  let deployer;
  let alice;
  let bob;
  let instanceToken;
  let instanceNFT;
  let instanceController;

  async function deployFixture() {
    [deployer, alice, bob] = await ethers.getSigners();

    // deploy the token
    const MyToken = await ethers.getContractFactory("MyToken");
    instanceToken = await upgrades.deployProxy(MyToken, [1_000_000, "MyToken", "MYT", ethers.constants.AddressZero]); // use the upgradeable patterns
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

    return { instanceToken, instanceNFT, instanceController, deployer, alice, bob };
  }

  it('Should deploy to an address', async () => {
    const { instanceToken, instanceNFT, instanceController } = await loadFixture(deployFixture);

    expect(await instanceToken.address).to.not.be.null;
    expect(await instanceToken.address).to.be.properAddress;

    expect(await instanceNFT.address).to.not.be.null;
    expect(await instanceNFT.address).to.be.properAddress;

    expect(await instanceController.address).to.not.be.null;
    expect(await instanceController.address).to.be.properAddress;
  });

  it('Should create and transfer NFTs', async () => {
    const { instanceNFT, instanceController, deployer, alice, bob } = await loadFixture(deployFixture);

    expect(await instanceNFT.balanceOf(deployer.address)).to.equal(0);
    expect(await instanceNFT.balanceOf(alice.address)).to.equal(0);
    expect(await instanceNFT.balanceOf(bob.address)).to.equal(0);

    let tx = await instanceNFT.connect(alice).mint();
    await tx.wait();

    expect(await instanceNFT.balanceOf(deployer.address)).to.equal(0);
    expect(await instanceNFT.balanceOf(alice.address)).to.equal(1);
    expect(await instanceNFT.balanceOf(bob.address)).to.equal(0);

    // bob cannot transfer alice's NFT
    await expect(instanceNFT.connect(bob).transferFrom(alice.address, bob.address, 0)).to.be.revertedWith(
        "ERC721: caller is not token owner or approved"
    );

    // but alice can transfer to bob
    tx = await instanceNFT.connect(alice).transferFrom(alice.address, bob.address, 0);
    await tx.wait();

    expect(await instanceNFT.balanceOf(deployer.address)).to.equal(0);
    expect(await instanceNFT.balanceOf(alice.address)).to.equal(0);
    expect(await instanceNFT.balanceOf(bob.address)).to.equal(1);
    
    await expect(instanceNFT.connect(alice).transferFrom(alice.address, bob.address, 0)).to.be.revertedWith(
        "ERC721: caller is not token owner or approved"
    );

    // the deployer cannot force transfer (on the non-god-mode NFT)
    await expect(instanceNFT.connect(deployer).transferFrom(bob.address, alice.address, 0)).to.be.revertedWith(
        "ERC721: caller is not token owner or approved"
    );

    expect(await instanceController.stakedNFT()).to.equal(instanceNFT.address);
  });

  it("Should upgrade the NFT to support God mode", async () => {
    const { instanceNFT, deployer, alice, bob } = await loadFixture(deployFixture);

    expect(await instanceNFT.balanceOf(deployer.address)).to.equal(0);
    expect(await instanceNFT.balanceOf(alice.address)).to.equal(0);
    expect(await instanceNFT.balanceOf(bob.address)).to.equal(0);

    tx = await instanceNFT.connect(alice).mint();
    await tx.wait();

    expect(await instanceNFT.balanceOf(deployer.address)).to.equal(0);
    expect(await instanceNFT.balanceOf(alice.address)).to.equal(1);
    expect(await instanceNFT.balanceOf(bob.address)).to.equal(0);

    // ensure that god mode does not work on the original contract:
    await expect(instanceNFT.connect(deployer).transferFrom(alice.address, bob.address, 0)).to.be.revertedWith("ERC721: caller is not token owner or approved");

    // but alice can move the nft
    tx = await instanceNFT.connect(alice).transferFrom(alice.address, bob.address, 0);
    await tx.wait();

    expect(await instanceNFT.balanceOf(deployer.address)).to.equal(0);
    expect(await instanceNFT.balanceOf(alice.address)).to.equal(0);
    expect(await instanceNFT.balanceOf(bob.address)).to.equal(1);

    tx = await instanceNFT.connect(bob).transferFrom(bob.address, alice.address, 0);
    await tx.wait();

    expect(await instanceNFT.balanceOf(deployer.address)).to.equal(0);
    expect(await instanceNFT.balanceOf(alice.address)).to.equal(1);
    expect(await instanceNFT.balanceOf(bob.address)).to.equal(0);

    // replace the old NFT instance with the new one:
    MyNFTGodMode = await ethers.getContractFactory("MyNFTGodMode");
    const instanceNFTGodMode = await upgrades.upgradeProxy(instanceNFT.address, MyNFTGodMode, {deployer});
    // ensure that the upgrade happened:
    expect(await instanceNFTGodMode.address).to.not.be.null;
    expect(await instanceNFTGodMode.address).to.be.properAddress;

    // now we can God-mode transfer!
    let god = deployer;
    // ..alice has it
    expect(await instanceNFTGodMode.balanceOf(deployer.address)).to.equal(0);
    expect(await instanceNFTGodMode.balanceOf(alice.address)).to.equal(1);
    expect(await instanceNFTGodMode.balanceOf(bob.address)).to.equal(0);

    // the old contract still exists!
    expect(await instanceNFT.balanceOf(deployer.address)).to.equal(0);
    expect(await instanceNFT.balanceOf(alice.address)).to.equal(1);
    expect(await instanceNFT.balanceOf(bob.address)).to.equal(0);

    // but only the new one can force tranger:
    tx = await instanceNFTGodMode.connect(god).forceTransfer(alice.address, bob.address, 0);
    await tx.wait();

    // not the old one:
    try {
      tx = await instanceNFT.connect(bob).forceTransfer(alice.address, bob.address, 0);
      await tx.wait();
      throw new Error("shouldnt be here");
    } catch (e) {
      // throws typeerror
    }
    
    // ..now bob has it even if against his will
    expect(await instanceNFTGodMode.balanceOf(deployer.address)).to.equal(0);
    expect(await instanceNFTGodMode.balanceOf(alice.address)).to.equal(0);
    expect(await instanceNFTGodMode.balanceOf(bob.address)).to.equal(1);

    // alice mints an NFT
    tx = await instanceNFTGodMode.connect(alice).mint();
    await tx.wait();
    expect(await instanceNFTGodMode.balanceOf(deployer.address)).to.equal(0);
    expect(await instanceNFTGodMode.balanceOf(alice.address)).to.equal(1);
    expect(await instanceNFTGodMode.balanceOf(bob.address)).to.equal(1);

    // bob cannot steal it
    await expect(instanceNFTGodMode.connect(bob).transferFrom(alice.address, bob.address, 0)).to.be.revertedWith(
        "ERC721: transfer from incorrect owner"
    );
    expect(await instanceNFTGodMode.balanceOf(deployer.address)).to.equal(0);
    expect(await instanceNFTGodMode.balanceOf(alice.address)).to.equal(1);
    expect(await instanceNFTGodMode.balanceOf(bob.address)).to.equal(1);
    
    // but god can:
    tx = await instanceNFTGodMode.connect(god).forceTransfer(alice.address, bob.address, 1);
    await tx.wait();

    expect(await instanceNFTGodMode.balanceOf(deployer.address)).to.equal(0);
    expect(await instanceNFTGodMode.balanceOf(alice.address)).to.equal(0);
    expect(await instanceNFTGodMode.balanceOf(bob.address)).to.equal(2);

    // and god can keep going
    tx = await instanceNFTGodMode.connect(god).forceTransfer(bob.address, deployer.address, 0);
    await tx.wait();

    expect(await instanceNFTGodMode.balanceOf(deployer.address)).to.equal(1);
    expect(await instanceNFTGodMode.balanceOf(alice.address)).to.equal(0);
    expect(await instanceNFTGodMode.balanceOf(bob.address)).to.equal(1);

    tx = await instanceNFTGodMode.connect(god).forceTransfer(bob.address, deployer.address, 1);
    await tx.wait();

    expect(await instanceNFTGodMode.balanceOf(deployer.address)).to.equal(2);
    expect(await instanceNFTGodMode.balanceOf(alice.address)).to.equal(0);
    expect(await instanceNFTGodMode.balanceOf(bob.address)).to.equal(0);
  });
});