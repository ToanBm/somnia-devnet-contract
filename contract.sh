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
      accounts: [0x${process.env.PRIVATE_KEY}],     // Replace with your private key or use environment variables for security
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
mkdir scripts

cat <<EOL > scripts/deploy.js
const { ethers } = require("hardhat");

async function main() {
    const [deployer] = await ethers.getSigners();
    const initialSupply = ethers.utils.parseUnits("1000000", "ether");

    const Token = await ethers.getContractFactory("MyToken");
    const token = await Token.deploy(initialSupply);

    console.log("Token deployed to:", token.address);
}

main().catch((error) => {
    console.error(error);
    process.exit(1);
});
EOL

# Step 7: Compile contracts
echo "Compile your contracts..."
npx hardhat compile

# "Waiting before deploying..."
sleep 10

# Step 8: Deploy the contract to the Hemi network
echo "Deploy your contracts..."
npx hardhat run scripts/deploy.js --network rome

echo "Thank you!"