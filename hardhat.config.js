require("@nomicfoundation/hardhat-toolbox");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.24",
  settings: {
    optimizer: {
      enabled: true,
      runs: 200,
    },
  },
  networks: {
    // Daftar jaringan lainnya
    volta: {
      url: "https://volta-rpc.energyweb.org/", // Ganti dengan URL RPC jaringan Volta
    },
  },
  paths: {
    contracts: "./contracts",
    artifacts: "./artifacts",
  },
};
