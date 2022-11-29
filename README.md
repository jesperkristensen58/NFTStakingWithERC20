<h1>Stake an NFT for rewards in an ERC20 Token</h1>

This contract gives you ability to stake your NFT(s) and earn reward tokens (an imagined ERC20 token) in return.

<h2>Description</h2>
Any owner of the NFT collection (see the contracts folder, MyNFT.sol) can stake their NFT into the Controller (Controller.sol) contract by sending their NFT to it. Then, each 24 hours, they receive 10 ERC20 Tokens (MyToken.sol) per staked NFT. If they withdraw, they forego the reward. The rewards only occur in 24-hour intervals. No partial rewards are given. So only after the delta time > 24 hours do they receive 10 tokens. If greater than 48 hours, they receive 20 tokens, and so on. They can claim multiple times, but only receive whatever they are entitled to between the last call and now.

## Deployment

Deployments took place on Goerli.

```
> npx hardhat run scripts/deploy.js --network goerli
Deploying with a an upgradeable proxy pattern.
============================================================
DEPLOYER:
Deploying contracts with the account:  0x4C6Caa288725b362d97728226e148680Ff7D1117
Account balance:                       973802662963632016
============================================================
MyToken Contract address: 0x618931C46CB8Cbb9Ce1e858ba8A6fa18151841Bb
MyNFT Contract address: 0x6B16dd3D4439feFA3e64cc98b907B5F3630C8b40
Controller Contract address: 0x108f62A1a426801148b07433456A7ABE16952D3a
```

The contracts were then verified with:

```
> npx hardhat verify 0x618931C46CB8Cbb9Ce1e858ba8A6fa18151841Bb --network goerli
Verifying implementation: 0xf2762F2cB27770F8492D89044e5958aEA70Cd5ce
Nothing to compile
Implementation 0xf2762F2cB27770F8492D89044e5958aEA70Cd5ce already verified.
Verifying proxy: 0x618931C46CB8Cbb9Ce1e858ba8A6fa18151841Bb
Contract at 0x618931C46CB8Cbb9Ce1e858ba8A6fa18151841Bb already verified.
Linking proxy 0x618931C46CB8Cbb9Ce1e858ba8A6fa18151841Bb with implementation
Successfully linked proxy to implementation.
Verifying proxy admin: 0xAE91efeAF5e4f706299EDE61b995439663c164Be
Contract at 0xAE91efeAF5e4f706299EDE61b995439663c164Be already verified.

Proxy fully verified.

> npx hardhat verify 0x6B16dd3D4439feFA3e64cc98b907B5F3630C8b40 --network goerli
Verifying implementation: 0x86132c7B35dD5E2ef4419F77002a940A0f9AAFd5
Nothing to compile
Successfully submitted source code for contract
contracts/MyNFT.sol:MyNFT at 0x86132c7B35dD5E2ef4419F77002a940A0f9AAFd5
for verification on the block explorer. Waiting for verification result...

Successfully verified contract MyNFT on Etherscan.
https://goerli.etherscan.io/address/0x86132c7B35dD5E2ef4419F77002a940A0f9AAFd5#code
Verifying proxy: 0x6B16dd3D4439feFA3e64cc98b907B5F3630C8b40
Contract at 0x6B16dd3D4439feFA3e64cc98b907B5F3630C8b40 already verified.
Linking proxy 0x6B16dd3D4439feFA3e64cc98b907B5F3630C8b40 with implementation
Successfully linked proxy to implementation.
Verifying proxy admin: 0xAE91efeAF5e4f706299EDE61b995439663c164Be
Contract at 0xAE91efeAF5e4f706299EDE61b995439663c164Be already verified.

Proxy fully verified.

> npx hardhat verify 0x108f62A1a426801148b07433456A7ABE16952D3a --network goerli
Verifying implementation: 0x52da92dc86b4037EaCa1399F63A8551aAe9C7484
Nothing to compile
Successfully submitted source code for contract
contracts/Controller.sol:Controller at 0x52da92dc86b4037EaCa1399F63A8551aAe9C7484
for verification on the block explorer. Waiting for verification result...

Successfully verified contract Controller on Etherscan.
https://goerli.etherscan.io/address/0x52da92dc86b4037EaCa1399F63A8551aAe9C7484#code
Verifying proxy: 0x108f62A1a426801148b07433456A7ABE16952D3a
Contract at 0x108f62A1a426801148b07433456A7ABE16952D3a already verified.
Linking proxy 0x108f62A1a426801148b07433456A7ABE16952D3a with implementation
Successfully linked proxy to implementation.
Verifying proxy admin: 0xAE91efeAF5e4f706299EDE61b995439663c164Be
Contract at 0xAE91efeAF5e4f706299EDE61b995439663c164Be already verified.

Proxy fully verified.
```

Now upgrade the NFT proxy:

```
npx hardhat run scripts/upgradeToGodMode.js --network goerli
Upgrading the proxy NFT contract.
============================================================
DEPLOYER:
Deploying contracts with the account:  0x4C6Caa288725b362d97728226e148680Ff7D1117
Account balance:                       966194880854859991
============================================================
Upgraded contract:  0x6B16dd3D4439feFA3e64cc98b907B5F3630C8b40
```

Now, before verifying it, etherscan showed this:

```
Implementation contract is now on 0x065f88606812529eb8b144bb0c16c88e8c9fdfab but NOT verified. Please request for the new implementation contract to be verified.
```

So we need to verify the upgraded NFT contract:

```
npx hardhat verify 0x6B16dd3D4439feFA3e64cc98b907B5F3630C8b40 --network goerli
Verifying implementation: 0x065f88606812529eB8b144BB0C16c88E8C9FdFAb
Nothing to compile
Successfully submitted source code for contract
contracts/MyNFTGodMode.sol:MyNFTGodMode at 0x065f88606812529eB8b144BB0C16c88E8C9FdFAb
for verification on the block explorer. Waiting for verification result...

Successfully verified contract MyNFTGodMode on Etherscan.
https://goerli.etherscan.io/address/0x065f88606812529eB8b144BB0C16c88E8C9FdFAb#code
Verifying proxy: 0x6B16dd3D4439feFA3e64cc98b907B5F3630C8b40
Contract at 0x6B16dd3D4439feFA3e64cc98b907B5F3630C8b40 already verified.
Linking proxy 0x6B16dd3D4439feFA3e64cc98b907B5F3630C8b40 with implementation
Successfully linked proxy to implementation.
Verifying proxy admin: 0xAE91efeAF5e4f706299EDE61b995439663c164Be
Contract at 0xAE91efeAF5e4f706299EDE61b995439663c164Be already verified.

Proxy fully verified.
```

Now verify this on etherscan by seeing the "write as proxy." Indeed I saw the new updated function:

```
https://goerli.etherscan.io/address/0x6B16dd3D4439feFA3e64cc98b907B5F3630C8b40#writeProxyContract#F2
```

## Upgrade the NFT

Upgrade the NFT contract to the God Mode version:

```
npx hardhat run scripts/upgradeToGodMode.js --network goerli
```

## Gas Report Result from using Clones

Note: The table below does not show up nicely in the markdown file, but if you open the file raw, the table will show
Here is a quick link: https://raw.githubusercontent.com/jesperkristensen58/NFTStakingWithERC20/main/README.md


·------------------------------------------------|---------------------------|---------------|-----------------------------·
|              Solc version: 0.8.16              ·  Optimizer enabled: true  ·  Runs: 10000  ·  Block limit: 30000000 gas  │
·················································|···························|···············|······························
|  Methods                                                                                                                 │
·····················|···························|·············|·············|···············|···············|··············
|  Contract          ·  Method                   ·  Min        ·  Max        ·  Avg          ·  # calls      ·  usd (avg)  │
·····················|···························|·············|·············|···············|···············|··············
|  ERC20Upgradeable  ·  transferFrom             ·          -  ·          -  ·        62452  ·            6  ·          -  │
·····················|···························|·············|·············|···············|···············|··············
|  MyNFT             ·  mint                     ·      82243  ·      99343  ·        93643  ·            6  ·          -  │
·····················|···························|·············|·············|···············|···············|··············
|  MyNFTGodMode      ·  forceTransfer            ·      47186  ·      69074  ·        56930  ·            8  ·          -  │
·····················|···························|·············|·············|···············|···············|··············
|  MyTokenFactory    ·  createNewERC20           ·    1608850  ·    1608862  ·      1608856  ·            4  ·          -  │
·····················|···························|·············|·············|···············|···············|··············
|  MyTokenFactory    ·  createNewERC20WithClone  ·     270555  ·     270567  ·       270561  ·            4  ·          -  │
·····················|···························|·············|·············|···············|···············|··············

We see that:

 + createNewERC20 takes up an average of <u>**1,608,856 gas**</u>.
 + createNewERC20WithClone using the Clones pattern takes up an average of <u>**270,561 gas**</u>.

Note that each was called 4 times in total.

Thus, using the Clones pattern in this specific setting is ~16.8% of the vanilla creation approach (and thus >80% more gas efficient on contract creation).

## Contact
[![Twitter URL](https://img.shields.io/twitter/url/https/twitter.com/cryptojesperk.svg?style=social&label=Follow%20%40cryptojesperk)](https://twitter.com/cryptojesperk)


## License
This project uses the following license: [MIT](https://github.com/bisguzar/twitter-scraper/blob/master/LICENSE).
