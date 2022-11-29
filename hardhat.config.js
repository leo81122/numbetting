require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

GOERLI_URL = process.env.GOERLI_URL;
PRIVATE_KEY = process.env.PRIVATE_KEY;
ETHERSCAN_API_KEY = process.env.ETHERSCAN_API_KEY;

// set proxy for access to etherscan
const proxyUrl = "http://127.0.0.1:8001"; // local proxy port
const { ProxyAgent, setGlobalDispatcher } = require("undici");
const proxyAgent = new ProxyAgent(proxyUrl);
setGlobalDispatcher(proxyAgent);

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.17",
  networks: {
    goerli: {
      url: GOERLI_URL,
      accounts: [PRIVATE_KEY],
    },
  },
  etherscan: {
    apiKey: ETHERSCAN_API_KEY,
  },
};
