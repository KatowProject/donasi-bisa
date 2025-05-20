import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "hardhat-tracer";
import "hardhat-gas-reporter";

const config: HardhatUserConfig = {
  solidity: "0.8.24",
  gasReporter: {
    enabled: true,
    currency: "IDR",
    coinmarketcap: "98ada0b3-87fc-459e-9b33-6ca3be58859d",
    token: "ETH",
    gasPrice: 2.5,
  },
};

export default config;
