require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-ethers");
require("@nomiclabs/hardhat-etherscan");
require('dotenv').config();

const { API_URL, PRIVATE_KEY, MAIN_API_URL } = process.env;
// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: {
    version: "0.8.13",
    settings: {
      optimizer: {
        enabled: true,
      }
    }
  },
  paths: {
    artifacts: './src/artifacts'
  },
  defaultNetwork: "binance_testnet",
  networks: {
    hardhat: {},
    binance_testnet: {
      url: API_URL,
      allowUnlimitedContractSize: true,
      accounts: [`0x${PRIVATE_KEY}`]
    },
    binance_mainnet: {
      url: MAIN_API_URL,
      allowUnlimitedContractSize: true,
      accounts: [`0x${PRIVATE_KEY}`]
    }
  },
  etherscan: {
    apiKey: {
      bscTestnet :"Z6I6T31HFWKTBNB476KTM87ANWCS4MK8FS",
    }
  }
};
