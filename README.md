<h1>Stake an NFT for rewards in an ERC20 Token</h1>

This contract gives you ability to stake your NFT(s) and earn reward tokens (an imagined ERC20 token) in return.

<h2>Description</h2>
Any owner of the NFT collection (see the contracts folder, MyNFT.sol) can stake their NFT into the Controller (Controller.sol) contract by sending their NFT to it. Then, each 24 hours, they receive 10 ERC20 Tokens (MyToken.sol) per staked NFT. If they withdraw, they forego the reward. The rewards only occur in 24-hour intervals. No partial rewards are given. So only after the delta time > 24 hours do they receive 10 tokens. If greater than 48 hours, they receive 20 tokens, and so on. They can claim multiple times, but only receive whatever they are entitled to between the last call and now.

## Deployment

Deployments took place on Goerli.

Token deployed at: 0xFFA0158422Bed94335001120Cd86670Ea51B0720
NFT deployed at: 0xFd83B5256c190b8dCd48992d91B20863587Bf13f
Controller deployed at: 0x2ee05Bb7c018af753DA1292063DbC2DD65a7A15e

The contracts were then verified with:

```
> npx hardhat verify 0xFFA0158422Bed94335001120Cd86670Ea51B0720
(...)

> npx hardhat verify 0xFd83B5256c190b8dCd48992d91B20863587Bf13f
Verifying implementation: 0x302c7F5CC9Eb8fb5Ca20DA4C915F3de0904527F3
Compiled 19 Solidity files successfully
Successfully submitted source code for contract
contracts/MyNFT.sol:MyNFT at 0x302c7F5CC9Eb8fb5Ca20DA4C915F3de0904527F3
for verification on the block explorer. Waiting for verification result...

Successfully verified contract MyNFT on Etherscan.
https://goerli.etherscan.io/address/0x302c7F5CC9Eb8fb5Ca20DA4C915F3de0904527F3#code
Verifying proxy: 0xFd83B5256c190b8dCd48992d91B20863587Bf13f
Contract at 0xFd83B5256c190b8dCd48992d91B20863587Bf13f already verified.
Linking proxy 0xFd83B5256c190b8dCd48992d91B20863587Bf13f with implementation
Successfully linked proxy to implementation.
Verifying proxy admin: 0xAE91efeAF5e4f706299EDE61b995439663c164Be
Contract at 0xAE91efeAF5e4f706299EDE61b995439663c164Be already verified.

Proxy fully verified.

> npx hardhat verify 0x2ee05Bb7c018af753DA1292063DbC2DD65a7A15e
Verifying implementation: 0x54a09F5B0fD46Da1663ca07A329C747C73ae5e47
Nothing to compile
Successfully submitted source code for contract
contracts/Controller.sol:Controller at 0x54a09F5B0fD46Da1663ca07A329C747C73ae5e47
for verification on the block explorer. Waiting for verification result...

Successfully verified contract Controller on Etherscan.
https://goerli.etherscan.io/address/0x54a09F5B0fD46Da1663ca07A329C747C73ae5e47#code
Verifying proxy: 0x2ee05Bb7c018af753DA1292063DbC2DD65a7A15e
Contract at 0x2ee05Bb7c018af753DA1292063DbC2DD65a7A15e already verified.
Linking proxy 0x2ee05Bb7c018af753DA1292063DbC2DD65a7A15e with implementation
Successfully linked proxy to implementation.
Verifying proxy admin: 0xAE91efeAF5e4f706299EDE61b995439663c164Be
Contract at 0xAE91efeAF5e4f706299EDE61b995439663c164Be already verified.

Proxy fully verified.
```

## Contact
[![Twitter URL](https://img.shields.io/twitter/url/https/twitter.com/cryptojesperk.svg?style=social&label=Follow%20%40cryptojesperk)](https://twitter.com/cryptojesperk)


## License
This project uses the following license: [MIT](https://github.com/bisguzar/twitter-scraper/blob/master/LICENSE).
