<h1>Stake an NFT for rewards in an ERC20 Token</h1>

This contract gives you ability to stake your NFT(s) and earn reward tokens (an imagined ERC20 token) in return.

<h2>Description</h2>
Any owner of the NFT collection (see the contracts folder, MyNFT.sol) can stake their NFT into the Controller (Controller.sol) contract by sending their NFT to it. Then, each 24 hours, they receive 10 ERC20 Tokens (MyToken.sol) per staked NFT. If they withdraw, they forego the reward. The rewards only occur in 24-hour intervals. No partial rewards are given. So only after the delta time > 24 hours do they receive 10 tokens. If greater than 48 hours, they receive 20 tokens, and so on. They can claim multiple times, but only receive whatever they are entitled to between the last call and now.

## Contact
[![Twitter URL](https://img.shields.io/twitter/url/https/twitter.com/cryptojesperk.svg?style=social&label=Follow%20%40cryptojesperk)](https://twitter.com/cryptojesperk)


## License
This project uses the following license: [MIT](https://github.com/bisguzar/twitter-scraper/blob/master/LICENSE).
