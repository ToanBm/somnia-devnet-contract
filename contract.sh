#!/bin/bash

BOLD=$(tput bold)
RESET=$(tput sgr0)
YELLOW=$(tput setaf 3)

print_command() {
  echo -e "${BOLD}${YELLOW}$1${RESET}"
}

# Logo
echo -e "\033[0;34m"
echo "Logo is comming soon..."
echo -e "\e[0m"

# Step 1: Install hardhat
echo "Install Hardhat..."
npm init -y
npm install --save-dev hardhat @nomiclabs/hardhat-ethers ethers @openzeppelin/contracts
echo "Install dotenv..."
npm install dotenv

# Step 2: Automatically choose "Create an empty hardhat.config.js"
echo "Creating project with an empty hardhat.config.js..."
npx hardhat init

# Step 3: Create MyToken.sol contract
echo "Create ERC20 contract..."
rm -rf contracts/Lock.sol
cat <<EOL > contracts/BuyMeCoffee.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract BuyMeCoffee {
    event CoffeeBought(
        address indexed supporter,
        uint256 amount,
        string message,
        uint256 timestamp
    );

    address public owner;

    struct Contribution {
        address supporter;
        uint256 amount;
        string message;
        uint256 timestamp;
    }
    
    Contribution[] public contributions;

    constructor() {
        owner = msg.sender;
    }

    function buyCoffee(string memory message) external payable {
        require(msg.value > 0, "Amount must be greater than zero.");
        contributions.push(
            Contribution(msg.sender, msg.value, message, block.timestamp)
        );

        emit CoffeeBought(msg.sender, msg.value, message, block.timestamp);
    }

    function withdraw() external {
        require(msg.sender == owner, "Only the owner can withdraw funds.");
        payable(owner).transfer(address(this).balance);
    }

    function getContributions() external view returns (Contribution[] memory) {
        return contributions;
    }

    function setOwner(address newOwner) external {
        require(msg.sender == owner, "Only the owner can set a new owner.");
        owner = newOwner;
    }
}
EOL

# Step 4: Create .env file for storing private key
echo "Create .env file..."

read -p "Enter your EVM wallet private key (without 0x): " PRIVATE_KEY
cat <<EOF > .env
PRIVATE_KEY=$PRIVATE_KEY
EOF

# Step 5: Update hardhat.config.js with the proper configuration
echo "Creating new hardhat.config file..."
rm hardhat.config.ts

cat <<EOL > hardhat.config.ts
import type { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox-viem";
require("dotenv").config();

module.exports = {
  solidity: {
    version: "0.8.28",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  networks: {
    somnia: {
      url: "https://dream-rpc.somnia.network", // Replace with the Somnia network RPC URL
      accounts: [process.env.PRIVATE_KEY ? `0x${process.env.PRIVATE_KEY}` : ""],     // Replace with your private key or use environment variables for security
    },
  },
};

const config: HardhatUserConfig = {
  solidity: "0.8.28",
};

export default config;
EOL

# Step 6: Create deploy script
echo "Creating deploy script..."
rm -rf ignition/modules/Lock.ts

cat <<EOL > ignition/modules/deploy.ts
import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const BuyMeCoffee = buildModule("BuyMeCoffee", (m) => {
  const contract = m.contract("BuyMeCoffee");
  return { contract };
});

module.exports = BuyMeCoffee;
EOL

# Step 7: Compile contracts
echo "Compile your contracts..."
npx hardhat compile

# "Waiting before deploying..."
sleep 3

# Step 8: Deploy the contract to the Hemi network
echo "Deploy your contracts..."
npx hardhat ignition deploy ./ignition/modules/deploy.ts --network somnia

echo "Thank you!"
