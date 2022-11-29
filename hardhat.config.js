require('@nomicfoundation/hardhat-toolbox');
require('@openzeppelin/hardhat-upgrades'); // to enable upgradeability
require("hardhat-gas-reporter");
require('dotenv').config()

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  defaultNetwork: "hardhat",
  solidity: "0.8.16",
  etherscan: {
    apiKey: process.env.API_KEY_ETHERSCAN,
  },
  networks: {
    hardhat: {
    },
    goerli: {
      url: `https://eth-goerli.g.alchemy.com/v2/${process.env.API_KEY}`,
      accounts: [process.env.PRIVATE_KEY_DEPLOYER]
    }
  },
  gasReporter: {
    enabled: true,
    currency: 'USD',
    gasPrice: 21
  },
  solidity: {
    version: "0.8.16",
    settings: {
      optimizer: {
        enabled: true,
        runs: 10000
      }
    }
  },
  mocha: {
    timeout: 100000000
  },
};
